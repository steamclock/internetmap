
#import results # Not using results?
import loc

import json

#asinfo = results.asinfo
locinfo = loc.locinfo
#fields = asinfo["fields"]
#del asinfo["fields"]
#print fields

# for asn, dat in asinfo.items():
# 	if int(asn) in locinfo:
# 		dat.extend(locinfo[int(asn)])
# 	else:
# 		dat.extend([0, 0])
# 
# for asn, dat in asinfo.items():
# 	print asn, dat[0]
# 	if asn != dat[0]:
# 		print "\n\n\n\n\n\n\n"

print locinfo
# for val in locinfo.values():
# 	print val
# 	udata = val[0].decode("utf-8");
# 	val[0] = udata.encode("ascii", "ignore")
	# val[0] = unicode(val[0])
	# print val
f = open("asinfo.json", "w")
json.dump(locinfo, f)
f.close()