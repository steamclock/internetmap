
# open oldest file

# age
#   decimation
#   or find reg dates!

# write out

from asgraph import *
import os
import random

# dir = os.listdir("data")
# for filename in dir:
# 	if filename[0:5] == "cycle":
# 		outfilename = filename[28:36]
# 	else:
# 		outfilename = filename[17:26]
# 	outfilename += ".txt"
# 	print outfilename
# 	asg = ASGraph("data/" + filename)
# 	cg = CentralityGraph(asg, scale = 4*inches(1.714286), logbase = 2)
# 	cg.writeData("out/" + outfilename);


from types import MethodType

random.seed(1)

# def decimate(self, pct):
# 	order = self.Order()
# 	print "current order:", order
# 	target = int(pct*order)
# 	print "decimate to ", target
# 	diff = order - target
# 	hitlist = {}
# 	for i in range(diff):
# 		n = random.randrange(order)
# 		while n in hitlist:
# 			n = random.randrange(order)
# 		hitlist[n] = True
# 	# print hitlist.keys()
# 	# print self.graph.node.keys()
# 	nodes = self.graph.node.keys()
# 	nodestoremove = [nodes[i] for i in hitlist.keys()]
# 	# print nodestoremove
# 	for node in nodestoremove:
# 		if node not in self.graph.node:
# 			# print "skipping a missing node"
# 			continue
# 		self.graph.remove_node(node)
# 		subgraphs = nx.connected_component_subgraphs(self.graph)
# 		subgraphlist = [(graph.order(), graph) for graph in subgraphs]
# 		subgraphlist.sort(key = lambda subgraph: -subgraph[0])
# 		# print subgraphlist
# 		self.graph = subgraphlist[0][1]
# 		# print self.Order()
# 		
# 		if self.Order() <= target:
# 			break
# 	print "final size:", self.Order()
# 	print "connected components:", nx.number_connected_components(self.graph)
# 		
# 	
# ASGraph.decimate = MethodType(decimate, None, ASGraph)
# 
# asg = ASGraph("data/skitter_as_links.20000102")
# for year in range(1999, 1993, -1):
# 	print "year: ", year
# 	# asg.decimate(.698)
# 	asg.decimate(.768)
# 	cg = CentralityGraph(asg, scale = 4*inches(1.714286), logbase = 2)
# 	cg.writeData("out/" + str(year) + "0101.txt");

nextasn = 8192 << 16
def getASN():
	global nextasn
	asn = nextasn
	nextasn += 1
	return str(asn)

def grow(self, pct):
	order = self.Order()
	print "current order:", order
	target = int(pct*order)
	print "grow to ", target
	diff = target - order
	centrality = eigenvector.centrality(self.graph)
	clist = centrality.items()
	clist.sort(key = lambda item: -item[1])
	caslist, cclist = zip(*clist)

	newgraph = self.graph.copy()
	for i in range(diff):
		asn = caslist[random.randrange(order)]
		neighbors = self.graph.neighbors(asn)
		newasn = getASN()
		for neighbor in neighbors:
			ind = caslist.index(neighbor)
			ind += random.randrange(15)
			if ind >= len(caslist):
				ind -= 20
			newgraph.add_edge(newasn, caslist[ind])
	self.graph = newgraph
	print "final size: ", self.graph.order(), self.graph.size()
	
	

ASGraph.grow = MethodType(grow, None, ASGraph)

asg = ASGraph("data/cycle-aslinks.l7.t1.c002312.20130102.txt")
for year in range(2014, 2031):
	print "year: ", year
	asg.grow(1.09)
	if year == 2020 or year == 2030:
		cg = CentralityGraph(asg, scale = 4*inches(1.714286), logbase = 2)
		cg.writeData("out/" + str(year) + "0101.txt");
