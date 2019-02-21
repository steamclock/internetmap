
# for each AS:
#   find all IP blocks
#   for each IP block:
#     find all locations
#   find location that corresponds to largest total IP space

import json
import csv
import random
import ipaddress

debug = False # Shows verbose debug prints if True
debugMaxCounter = 50 # Set to limit number of iterations through CSVs. Makes high level testing quicker.

class IPBlock:
	def __init__(self, ipfirst, iplast, as_):
		self.ipfirst = ipfirst
		self.iplast = iplast
		self.blocksize = iplast - ipfirst + 1
		self.as_ = as_

class AS:
	def __init__(self, asnum, name):
		self.asnum = asnum
		self.name = name
		self.ipblocks = []
		self.locdic = {}
		self.lat = 0
		self.lng = 0
		self.loc = None
	def __repr__(self):
		return "AS" + str(self.asnum) + "|" + self.name + "}" + str(len(self.ipblocks)) + " blocks"

class Location:
	def __init__(self, lat, lng, city):
		self.lat = lat
		self.lng = lng
		self.city = city
		self.used = False

def listinsert(item, thelist, start = 0, end = None):
	if end is None:
		end = len(list) - 1
	if start == end:
		return thelist[:start] + [item] + thelist[start:]
	
def IPv4CIDRtoIPStartEnd(cidr):
	n = ipaddress.IPv4Network(cidr)
	return int(n[0]), int(n[-1])
	
class IPBlockList:
	def __init__(self):
		self.blocklist = []
	def insert(self, ipblock):
		insertpoint = len(self.blocklist)
		# print "starting search len = ", len(self.blocklist)
		for i in range(len(self.blocklist)):
			# print "i = ", i
			# print ipblock.ipfirst, self.blocklist[i].ipfirst
			if ipblock.ipfirst < self.blocklist[i].ipfirst:
				insertpoint = i
				break
		self.blocklist = self.blocklist[:insertpoint] + [ipblock] + self.blocklist[insertpoint:] 
		# print "returning"
	def findBlock(self, ipfirst, iplast):
		for block in self.blocklist:
			if ipfirst > block.iplast or iplast < block.ipfirst:
				continue
			return block
		return None
		

# Step 1: Create ASN dictionary (asdic) that maps ASN numbers to blocks of IPs "owned" by the ASN.
blocklistdic = {}
asdic = {}

print "\n\n=== Starting geo location (loc.py) generation ==="
print "\n> Creating IP Blocklist (to ASN) lookup..."
with open('data/GeoLite2-ASN-Blocks-IPv4.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	counter = 0

	next(reader, None) # Skip the header

	for row in reader:
		counter += 1
		# if counter < 100:
		# 	print row
	
		cidr = row[0]
		asnum = int(row[1])
		asname = row[2]
		firstip, lastip = IPv4CIDRtoIPStartEnd(cidr)
		blockId = firstip >> 16

		#print str(firstip) + " " + str(lastip)

		# Add ASN to asn dictionary
		if asnum not in asdic:
			asdic[asnum] = AS(asnum, asname)
		as_ = asdic[asnum]
	
		# Add IP block to block dictionary
		if blockId not in blocklistdic:
			blocklistdic[blockId] = IPBlockList()
		blocklist = blocklistdic[blockId]
		
		# Associate IPBlock with ASN 
		newblock = IPBlock(firstip, lastip, as_)
		blocklist.insert(newblock)
		as_.ipblocks.append(newblock)

		if (debug):
			if (counter > debugMaxCounter):
				break

	print "Completed. " + str(len(blocklistdic)) + " IP Blocks found over " + str(counter) + " rows"


# Step 2: Generate the location DB lookup table that will associate a Geoname (id) with an English
# city name. Note, our new data file does not contain lat/lng. That will get filled in at a later step.
locdb = {}
print "\n> Creating Geoname location lookup table..."
with open('data/GeoLite2-City-Locations-en.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	counter = 0

	next(reader, None) # Skip the header

	for row in reader:
		counter += 1
		
		loc = int(row[0]) # Use Geoname ID as location UUID
		city = row[10]

		locdb[loc] = Location(-1, -1, city) # Don't know lat/lng yet

	print "Completed. " + str(len(locdb)) + " locations found"


# Step 3: For each IP Block, update the known location for that block and add the location 
# to the ASN associated with it.
print "\n> Converting IP blocks to locations..."
with open('data/GeoLite2-City-Blocks-IPv4.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	counter = 0
	successes = 0
	fails = 0

	next(reader, None) # Skip the header

	for row in reader:
		counter += 1
		# if counter % 1000 == 0:
		# 	print row
	 	#print row

		cidr = row[0]
		startip, endip = IPv4CIDRtoIPStartEnd(cidr)
		geonameId = row[1] # Use (city) Geoname id as location identifier
		#countryGeonameId = row[2] # Not sure if we need this
		lat = row[7]
		lng = row[8]
		
		if not geonameId:
			fails += 1
			continue

		loc = int(geonameId)
		blockId = startip >> 16

		if blockId not in blocklistdic:
			fails += 1
			continue

		# Lookup IPBlock in dictionary
		blocklist = blocklistdic[blockId]
		block = blocklist.findBlock(startip, endip)
		if block is None:
			fails += 1
			continue

		# Get the ASN associated with that IP Block; add the location to the ASNs locdic 
		# and calculate the number of IP adddress that this location hosts. This will be used
		# later to order the relative importance of the IP Blocks.
		as_ = block.as_
		if loc not in as_.locdic:
			as_.locdic[loc] = 0

		as_.locdic[loc] += endip - startip + 1

		if (not lat or not lng):
			#print("Failed to parse location for " + str(loc))
			fails += 1
			continue

		# Update locdb with lat/lng if possible.
		if loc in locdb:
			city = locdb[loc]
			city.lat = float(lat)
			city.lng = float(lng)

		successes += 1

		if (debug):
			print "Location ", loc, "now associated with [", lat, ", ", lng, "]"
			if (counter > debugMaxCounter):
				break

	print "Completed. Checked " + str(counter) + " IP Blocks"
	print "  Found locations: " + str(successes)
	print "  Failed to find location: " + str(fails)

# Step 4: Remove all locations from our DB that did not get updated lat/lng coordinates.
print "\n> Removing all locations with invalid lat/lng values..."
print "Starting with " + str(len(locdb)) + " unique geonamed locations"
tempLocDB = {}

for key,loc in locdb.items():
	if (loc.lat == -1 or loc.lng == -1):
		continue
	
	tempLocDB[key] = loc

	if (debug):
		print str(key), ": ", loc.city, "(", loc.lat, ", ", loc.lng, ")"

locdb = tempLocDB
print "Completed. There are " + str(len(locdb)) + " unique geonamed locations with lat/lng values"

# Step 4: Associate a single location to an ASN (based on the location of the largest block of IPs)
print "\n> Associating ASN locations to be the geo location that has the largest block of IPs"
for as_ in asdic.values():
	# Get all ipblocks associated with ASN
	items = as_.locdic.items();

	# Sort by number of IPs in the block descending
	items.sort(key = lambda item: -item[1])
	

	#print "--- " + as_.name + " ---"
	#for item in items:
	#	print item #"---", item[1], locdb[item[0]].city

	for item in items:
		locId = item[0]

		# If we do not have a location for that ID in our location dictionary, continue
		# and check the new block.
		if locId not in locdb:
			continue

		loc = locdb[locId]

		# If city is unknown, continue to check new block.
		if len(loc.city) == 0:
			continue

		as_.loc = locId
		break

	if as_.loc is None:
		if len(items) == 0:
			as_.loc = 0
		else:
			# print "choosing:", items[0][0].city
			as_.loc = items[0][0]

	if (debug):
		if as_.loc not in locdb:
			print as_.name + "(" + str(as_.asnum) + "): No city found"
		else: 
			print as_.name + "(" + str(as_.asnum) + "): Selected: locId(" + str(as_.loc) + "): " + locdb[as_.loc].city		

print "Complete."
	
# Step 5: Create final results dictionary by replacing some old ASN names if required.
print "\n> Creating final results dictionary, replacing old Cogeco names..."
oldPeer1Names = ["Peer 1 Network (USA) Inc.", "COGECODATA"]
newCogeconame = "Cogeco Peer 1"	
resultsdic = {}
notfound = 0

for as_ in asdic.values():
	# print as_.asnum, as_.name
	if as_.loc in locdb:
		loc = locdb[as_.loc]
		loc.used = True
		# print as_.asnum, loc.city
		# Replace Peer1 with Cogeco
		if as_.name in oldPeer1Names:
			as_.name = newCogeconame	

		resultsdic[as_.asnum] = [as_.name, loc.lat, loc.lng]
	else:
		# print "not found!"
		notfound += 1

print "Complete."
print notfound, "locations not found"

# Step 6: Creating fake ASNs based on large locations that have not already been used?
# Not sure WHY this is being done, but was included in the original script. Perhaps to do 
# with projected data?
print "\n> Generating random ASNs based on unused DB values"
random.seed(4)
unused = [loc for loc in locdb.values() if not loc.used]
for i in range(19009):
 #for i in range(12009):
	asnum = (8192 << 16) + i
	loc = unused[random.randrange(len(unused))]
	# resultsdic[asnum] = ["", loc.lat + round(random.uniform(-0.1, 0.1), 4), loc.lng + round(random.uniform(-0.1, 0.1), 4)]
	resultsdic[asnum] = ["", loc.lat, loc.lng]
print "Complete."


# Step 7: gGnerate final results in separate file.
print "\n> Generating loc.py based on final results dictionary..."
outfile = open("../loc.py", "w")
outfile.write("locinfo = ")
outfile.write(repr(resultsdic))
outfile.close()
print "Complete.\n"
