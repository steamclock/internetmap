# 
# 2019-02-19
# geo_validate.py
#
# Created in an attempt to validify and compare the data created for 2018 (since our location data set changed due to data deprication)
# 
# 

import loc
import loc_2017
import json


oldLocInfo = loc_2017.locinfo
newLocinfo = loc.locinfo
newCogeconame = "Cogeco Peer 1"

continuingEntries = 0
locationChanged = 0
locationUnchanged = 0

counter = 0
 
newASNs = []
removedASNs = []

for key, newLoc in newLocinfo.items():

	asnName = newLoc[0]
	
	if (not asnName):
		continue

	isCogeco = (asnName == newCogeconame)

	if key in oldLocInfo:
		#print "\nMATCH (" + asnName + ")"

		continuingEntries += 1
		oldLoc = oldLocInfo[key]

		if (isCogeco):
			print "Old: " + str(key) + " : " + str(oldLoc)
			print "New: " + str(key) + " : " + str(newLoc)

		newLat = newLoc[1]
		newLng = newLoc[2]
		oldLat = oldLoc[1]
		oldLng = oldLoc[2]

		if (newLat != oldLat or newLng != oldLng):
			#print "Location changed"
			locationChanged += 1
			#print oldLoc
			#print newLoc
		else:
			#print "Location unchanged"
			locationUnchanged += 1

	else:
		newASNs.append(key)
		if (isCogeco):
			print "ALERT: New Cogeco ASN found -> " + str(key) + " : " + str(newLoc) 


	counter += 1
	#if (counter > 100):
	#	break

for key, oldLoc in oldLocInfo.items():

	asnName = oldLoc[0]

	if (not asnName):
		continue

	isCogeco = (asnName == newCogeconame)

	if key not in newLocinfo:
		removedASNs.append(key)
		if (isCogeco):
			print "ALERT: New Cogeco ASN removed -> " + str(key) + " : " + str(oldLoc) 
		

print "\n--- Summary ---"
print " Previous Year:"
print "   ASNs with locations: " + str(len(oldLocInfo))

print "\nNew Year:"
print "   ASNs with locations: " + str(len(newLocinfo))
print "   Existing ASNs: " + str(continuingEntries)
print "     Location Changed: " + str(locationChanged)
print "     Location Unchanged: " + str(locationUnchanged)
print "   New ASNs: " + str(len(newASNs))

showNumbers = str(raw_input("Show new ASN numbers (y/n)?: ")) # use input when we switch to python 3
if (showNumbers == "y" or showNumbers == "Y"):
	print "   " + str(newASNs)

print "   Removed ASNs: " + str(len(removedASNs))
showNumbers = str(raw_input("Show removed ASN numbers (y/n)?: ")) # use input when we switch to python 3
if (showNumbers == "y" or showNumbers == "Y"):
	print "   " + str(removedASNs)



