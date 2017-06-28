
# for each AS:
#   find all IP blocks
#   for each IP block:
#     find all locations
#   find location that corresponds to largest total IP space


import json
import csv
import random

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
		self.long = 0
		self.loc = None
	def __repr__(self):
		return "AS" + str(self.asnum) + "|" + self.name + "}" + str(len(self.ipblocks)) + " blocks"

def listinsert(item, thelist, start = 0, end = None):
	if end is None:
		end = len(list) - 1
	if start == end:
		return thelist[:start] + [item] + thelist[start:]
	
	
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
		

# load mapping of IP blocks to AS
blocklistdic = {}
asdic = {}

with open('data/GeoIPASNum2.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	counter = 0
	for row in reader:
		counter += 1
		# if counter < 100:
		# 	print row
		print row
		asstring = row[2].decode("latin1")
		ind = asstring.find(u" ")
		asnum = int(asstring[2:ind])
		asname = asstring[ind + 1:].encode("utf-8")

		if asnum not in asdic:
			asdic[asnum] = AS(asnum, asname)
		as_ = asdic[asnum]
		
		firstip = int(row[0])
		lastip = int(row[1])
		if firstip >> 16 not in blocklistdic:
			blocklistdic[firstip >> 16] = IPBlockList()
		blocklist = blocklistdic[firstip >> 16]
		
		newblock = IPBlock(firstip, lastip, as_)
		blocklist.insert(newblock)
		as_.ipblocks.append(newblock)

# print asdic
# print sorted(asdic.keys())


# print blocklist.blocklist
# print len(blocklist.blocklist)

# load geographic location blocks
with open('data/GeoLiteCity-Blocks.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	reader.next()
	reader.next()
	counter = 0
	for row in reader:
		counter += 1
		# if counter % 1000 == 0:
		# 	print row
		# print row
		startip = int(row[0])
		endip = int(row[1])
		loc = int(row[2])
		if startip >> 16 not in blocklistdic:
			continue
		blocklist = blocklistdic[startip >> 16]
		block = blocklist.findBlock(startip, endip)
		if block is None:
			continue
		as_ = block.as_
		if loc not in as_.locdic:
			as_.locdic[loc] = 0
		as_.locdic[loc] += endip - startip + 1

class Location:
	def __init__(self, lat, long, city):
		self.lat = lat
		self.long = long
		self.city = city
		self.used = False
		# print city

# 	load location DB
locdb = {}
with open('data/GeoLiteCity-Location.csv', 'rb') as csvfile:
	reader = csv.reader(csvfile)
	reader.next()
	reader.next()
	counter = 0
	for row in reader:
		counter += 1
		# if counter % 1000 == 0:
		# 	print row
		# print row
		loc = int(row[0])
		locdb[loc] = Location(float(row[5]), float(row[6]), row[3])
		# if row[1] == "FR":
		# 	print row
		

for as_ in asdic.values():
	# maxloc = 0
	# maxcount = 0
	# for loc, count in as_.locdic.items():
	# 	if count > maxcount:
	# 		maxloc = loc
	# 		maxcount = count
	# as_.loc = maxloc
	print "AS:", as_.asnum
	items = as_.locdic.items();
	items.sort(key = lambda item: -item[1])
	for item in items:
		print "---", item[1], locdb[item[0]].city
	for item in items:
		# print "looking at city:", locdb[item[0]].city
		if item[0] not in locdb:
			continue
		if len(locdb[item[0]].city) == 0:
			# print "ignoring empty city:", locdb[item[0]].city
			continue
		as_.loc = item[0]
		break
	if as_.loc is None:
		if len(items) == 0:
			as_.loc = 0
		else:
			# print "choosing:", items[0][0].city
			as_.loc = items[0][0]
	if as_.loc:
		print "----->", locdb[as_.loc].city
	
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

		resultsdic[as_.asnum] = [as_.name, loc.lat, loc.long]
	else:
		# print "not found!"
		notfound += 1
print notfound, "locations not found"

random.seed(4)
unused = [loc for loc in locdb.values() if not loc.used]
for i in range(19009):
# for i in range(12009):
	asnum = (8192 << 16) + i
	loc = unused[random.randrange(len(unused))]
	# resultsdic[asnum] = ["", loc.lat + round(random.uniform(-0.1, 0.1), 4), loc.long + round(random.uniform(-0.1, 0.1), 4)]
	resultsdic[asnum] = ["", loc.lat, loc.long]


# used = [True for loc in locdb.values() if loc.used]
# print "locations used: ", len(used), "/", len(locdb.values())

outfile = open("../loc.py", "w")
outfile.write("locinfo = ")
outfile.write(repr(resultsdic))
outfile.close()
