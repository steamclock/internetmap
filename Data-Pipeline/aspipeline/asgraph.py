
import networkx as nx
import eigenvector
from p9base import *
import math

EIGENVECTOR_CENTRALITY = 1
EIGENVECTOR_CENTRALITY_REV = 2
EDGE_CENTRALITY = 3

class Graph(object):
	def __init__(self):
		self.nodeorder = None
		self.edgeorder = None
		
	def Order(self):
		return self.graph.order()
		
	def Size(self):
		return self.graph.size()
		
	def SetNodeOrder(self, order):
		self.nodeorder = self.graph.nodes()
		if order == EIGENVECTOR_CENTRALITY:
			self.nodeorder.sort(key = lambda node: self.graph.node[node]["eigcent"], reverse = False)
		elif order == EIGENVECTOR_CENTRALITY_REV:
			self.nodeorder.sort(key = lambda node: self.graph.node[node]["eigcent"], reverse = True)
			# print [math.log(self.graph.node[node]["eigcent"]) for node in self.nodeorder]
		
	def GetNodes(self):
		return self.nodeorder

	def GetEdges(self):
		return self.edgeorder

	def SetEdgeOrder(self, order):
		self.edgeorder = self.graph.edges()
		if order == EDGE_CENTRALITY:
			self.edgeorder.sort(key = lambda edge: self.graph.edge[edge[0]][edge[1]]["edgeweight"], reverse = False)		
		
	def NodePos(self):
		assert(self.nodeorder is not None)
		return [vector2(self.graph.node[node]["x"], self.graph.node[node]["y"]) for node in self.nodeorder]
				
	def EdgePos0(self):
		assert(self.edgeorder is not None)
		return [vector2(self.graph.node[edge[0]]["x"], self.graph.node[edge[0]]["y"]) for edge in self.edgeorder]
		
	def EdgePos1(self):
		assert(self.edgeorder is not None)
		return [vector2(self.graph.node[edge[1]]["x"], self.graph.node[edge[1]]["y"]) for edge in self.edgeorder]

	def NodeCentrality(self):
		assert(self.nodeorder is not None)
		return [self.graph.node[node]["eigcent"] for node in self.nodeorder]
				
	def EdgeImportance(self):
		assert(self.edgeorder is not None)
		return [self.graph.edge[edge[0]][edge[1]]["edgeweight"] for edge in self.edgeorder]
		
	def NodeType(self):
		assert(self.nodeorder is not None)
		return [self.graph.node[node].get("type", None) for node in self.nodeorder]
				
	def CalcEigenvectorCentrality(self):
		centrality = eigenvector.centrality(self.graph)
		total = 0
		for node in centrality.items():
			self.graph.node[node[0]]["eigcent"] = node[1]
			total += node[1]
		# print "eigenvector centrality total: ", total
			
	def CalcEdgeCentrality(self):
		heaviest = 0
		for edge in self.graph.edges():
			weight = self.graph.node[edge[0]]["eigcent"]*self.graph.node[edge[1]]["eigcent"]
			self.graph.edge[edge[0]][edge[1]]["edgeweight"] = weight
			# if weight > heaviest:
			# 	print weight
			# 	heaviest = weight

	def GridAnnealedLayout(self, xdim, ydim, iterations, costfactor, start_threshold, data_filename, use_saved_data = False):
		assert(self.graph.order() <= xdim*ydim)

		def cost_per_length(edge_weight):
			# if costfactor is 0, cost is 1 for all weights of edges
			# if costfactor is 1, cost is proportional to weight of edge
			return 1 + costfactor*(10*edge_weight - 1)

		def calc_node_costs():
			for node in self.graph.nodes():
				self.graph.node[node]["nodecost"] = node_cost(node)

		def randomlayout(grid):
			poslist = [(x, y) for x in range(xdim) for y in range(ydim)]
			RGen(1).shuffle(poslist)
			for enumnode in enumerate(self.graph.nodes()):
				x = poslist[enumnode[0]][0]
				y = poslist[enumnode[0]][1]
				self.graph.node[enumnode[1]]["x"] = x
				self.graph.node[enumnode[1]]["y"] = y
				grid[gridkey(x, y)] = enumnode[1]

		def gridkey(x, y):
			return str(x) + "," + str(y)



		def anneal(grid, iterations):
			rgen = RGen(2)
			nodes = self.graph.nodes()
			numnodes = self.graph.order()
			for i in range(iterations):
				threshold = (1 - (float(i)/float(iterations)))*start_threshold
				thisnode = nodes[rgen.randrange(numnodes)]
				thisx = self.graph.node[thisnode]["x"]
				thisy = self.graph.node[thisnode]["y"]

				# destx = rgen.randrange(xdim)
				# desty = rgen.randrange(ydim)
				
				dist = int((iterations - i)*(xdim + ydim)/(iterations*4))
				dist = max(dist, 2)
				x = rgen.randrange(-dist, dist)
				y = dist - abs(x)
				if rgen.randrange(2) == 0:
					y = -y
				destx = thisx + x
				desty = thisy + y
				destx = max(0, min(destx, xdim - 1))
				desty = max(0, min(desty, ydim - 1))
				# print "x, y ", x, y, "   destx, desty ", destx, desty

				ediff = energy_diff(thisnode, destx, desty)
				destkey = gridkey(destx, desty)
				swapping = False
				reallyswapping = False
				if destkey in grid:
					swapping = True
					destnode = grid[destkey]
					ediff += energy_diff(destnode, thisx, thisy)
				if ediff < threshold:
					reallyswapping = True
					self.graph.node[thisnode]["x"] = destx
					self.graph.node[thisnode]["y"] = desty
					grid[destkey] = thisnode
					if swapping:
						self.graph.node[destnode]["x"] = thisx
						self.graph.node[destnode]["y"] = thisy
						grid[gridkey(thisx, thisy)] = destnode
					self.graph.node[thisnode]["nodecost"] = node_cost(thisnode)
					if swapping:
						self.graph.node[destnode]["nodecost"] = node_cost(destnode)
				# print "iteration ", i, "   energy_diff ", ediff, "   threshold ", threshold, "   swapping ", reallyswapping
						
			
		def edge_length(edge):
			n0 = self.graph.node[edge[0]]
			n1 = self.graph.node[edge[1]]
			dx = n1["x"] - n0["x"]
			dy = n1["y"] - n0["y"]
			return abs(dx) + abs(dy)

		def edge_weight(edge):
			return self.graph.edge[edge[0]][edge[1]]["edgeweight"]
	
		# bug: switch with neighbors won't be calculated properly

		def node_cost(node, pos = None):
			if pos is not None:
				x0, y0 = pos[0], pos[1]
			else:
				x0 = self.graph.node[node]["x"]
				y0 = self.graph.node[node]["y"]
			cost = 0
			for neighbor in self.graph.neighbors(node):
				x1 = self.graph.node[neighbor]["x"]
				y1 = self.graph.node[neighbor]["y"]
				d = abs(x1 - x0) + abs(y1 - y0)
				cost += d*cost_per_length(self.graph.edge[node][neighbor]["edgeweight"])
			return cost
		
		def energy_diff(node, destx, desty):
			return node_cost(node, (destx, desty)) - self.graph.node[node]["nodecost"]
		
		def totalcost():
			# for edge in self.graph.edges():
				# print "edgelength:", edge_length(edge), "  cost_per_length:", cost_per_length(edge_weight(edge))
			return sum(edge_length(edge)*cost_per_length(edge_weight(edge)) for edge in self.graph.edges())

		def save_data(filename):
			f = open(filename, "w")
			for node in self.graph.nodes():
				f.write(str(self.graph.node[node]["x"]) + "   " + str(self.graph.node[node]["y"]) + "\n")
			f.close()

		def load_data(filename):
			f = open(filename, "r")
			for node in self.graph.nodes():
				line = f.readline()
				tokens = line.split()
				self.graph.node[node]["x"] = int(tokens[0])
				self.graph.node[node]["y"] = int(tokens[1])
			f.close()

		print "calculating centrality"
		self.CalcEigenvectorCentrality()
		self.CalcEdgeCentrality()
		grid = {}
		randomlayout(grid)
		calc_node_costs()
		print "totalcost: ", totalcost()

		if use_saved_data:
			print "loading ", data_filename
			load_data(data_filename)
		else:
			print "annealing with ", iterations, "iterations"
			anneal(grid, iterations)
			print "saving to ", data_filename
			save_data(data_filename)

		print "totalcost: ", totalcost()
		



class ASGraph(Graph):
	def __init__(self, filename, attrfilename = None):
		super(ASGraph, self).__init__()
		asdatafile = open(filename)
		self.graph = nx.Graph()
		for line in asdatafile:
			tokens = line.split()
			if tokens[0] == "D" or tokens[0] == "I":
				if "_" in tokens[1] or "_" in tokens[2]:
					continue
				self.graph.add_edge(tokens[1], tokens[2])
		print "connected: ", nx.is_connected(self.graph)
		if not nx.is_connected(self.graph):
			for comp in nx.connected_components(self.graph)[1:]:
				for node in comp:
					self.graph.remove_node(node)
		# print self.graph.node
		if attrfilename is not None:
			attrdatafile = open(attrfilename)
			for line in attrdatafile:
				tokens = [token.strip() for token in line.split('\t')]
				# print tokens
				if tokens[0] in self.graph.node:
					self.graph.node[tokens[0]]["name"] = tokens[1]
					self.graph.node[tokens[0]]["type"] = tokens[7]
					# print self.graph.node[token[0]]
			
		print "loaded AS graph: ", filename
		print "order: ", self.graph.order(), "   size: ", self.graph.size()


class TestGraph(Graph):
	def __init__(self):
		super(TestGraph, self).__init__()
		self.graph = nx.complete_graph(60)
		print "order: ", self.graph.order(), "   size: ", self.graph.size()


class SubdivisionGrid(object):
	def find_nearest_open_point(self, pos):
		npiter = self.nearby_points(pos)
		candidates = []
		key, extrapoints = npiter.next()
		while key in self.grid:
			key, extrapoints = npiter.next()
		candidates.append(key)
		# print "extrapoints: ", extrapoints
		for i in range(extrapoints):
			key, extrapoints = npiter.next()
			if key not in self.grid:
				candidates.append(key)
		candidate_distances = [self.point_distance(key, pos) for key in candidates]
		closest = candidate_distances.index(min(candidate_distances))
		return candidates[closest]	

	# def mark_covered_spots(self, key, size):
	# 	npiter = self.nearby_points(pos)
	# 	candidates = []
	# 	key, extrapoints = npiter.next()
	# 	while key in self.grid:
	# 		key, extrapoints = npiter.next()

	
class SquareSubdivisionGrid(SubdivisionGrid):
	def __init__(self, parentgrid = None, numsubs = 2):
		assert(numsubs >= 2)
		self.grid = {}
		if parentgrid is None:
			self.TotalSubs = 1
		else:
			self.TotalSubs = parentgrid.TotalSubs*numsubs
			for item in parentgrid.grid.iteritems():
				self.grid[(item[0][0]*numsubs, item[0][1]*numsubs)] = item[1]
	
	def nearby_points(self, pos):
		x, y = int(pos.x), int(pos.y)
		yield (x, y), 0
		d = 1
		while True:
			extrarounds = math.ceil(d*.29 + 2)
			extrapoints = int(extrarounds*4*(d + extrarounds/2))
			yield (x + d, y), extrapoints
			yield (x - d, y), extrapoints
			yield (x, y + d), extrapoints
			yield (x, y - d), extrapoints
			for i in range(1, d):
				yield (x + (d - i), y + i), extrapoints
				yield (x - (d - i), y + i), extrapoints
				yield (x + (d - i), y - i), extrapoints
				yield (x - (d - i), y - i), extrapoints
			d += 1

	def point_distance(self, key, pos):
		keyvec = vector2(float(key[0]), float(key[1]))
		diff = keyvec - pos
		return diff.length()
	
	def AddNode(self, pos, node, size = None):
		subdivided_pos = pos.scale(self.TotalSubs)
		key = self.find_nearest_open_point(subdivided_pos)
		self.grid[key] = node
		# if size is not None:
		# 	if size > 0:
		# 		self.mark_covered_spots(key, size)
		return (self.TotalSubs, key)
		
	def NodePos(self, pos):
		return vector2(float(pos[1][0])/pos[0], float(pos[1][1])/pos[0])
		
	def LayerNum(self, pos):
		return math.log(pos[0], 2)
				
	def PosName(self):
		return "cgpos"

	def GetBBMax(self):
		maxval = 0
		for key in self.grid.keys():
			if abs(key[0]) > maxval:
				maxval = key[0]
			if abs(key[1]) > maxval:
				maxval = key[1]
		return float(maxval)/float(self.TotalSubs)




# max radius of node, expressed as a fraction of grid spacing
MAX_NODE_RADIUS = 0.1

OffsetVec = vector2(0, -.0)

class CentralityGraph(object):
	def __init__(self, graph, maxbbdim = None, scale = None, logbase = 2.71828183):
		self.graph = graph
		graph.CalcEigenvectorCentrality()
		graph.CalcEdgeCentrality()
		graph.SetNodeOrder(EIGENVECTOR_CENTRALITY_REV)
		nodes = graph.GetNodes()
		cents = graph.NodeCentrality()
		logs = [math.log(cent, logbase) for cent in cents]
		startlog = logs[0]
		loggrouping = [[] for i in range(30)]
		# print list(enumerate(logs))
		for logitem in enumerate(logs):
			loggrouping[int(math.floor(startlog - logitem[1]))].append(nodes[logitem[0]])
		self.grid = SquareSubdivisionGrid()
		for loggroup in loggrouping:
			for node in loggroup:
				pos = vector2(0, 0)
				totalcent = 0.0
				for neighbor in self.graph.graph.neighbors(node):
					# print "thisnode: ", node, "    neighbor: ", neighbor
					if nodes.index(neighbor) < nodes.index(node):
						neighborcent = self.graph.graph.node[neighbor]["eigcent"]
						# neighborcent = 1
						totalcent += neighborcent
						pos += self.node_pos(neighbor).scale(neighborcent)
				if totalcent != 0.0:
					pos = pos.scale(1.0/totalcent)
				self.graph.graph.node[node][self.grid.PosName()] = self.grid.AddNode(pos, node, math.sqrt(self.graph.graph.node[neighbor]["eigcent"])*24)
				# print "added node: ", node
			self.grid = SquareSubdivisionGrid(self.grid, 2)
		self.SetScale(maxbbdim, scale)
		# self.WriteIndexFile("../indexfile.txt", nodes)

	def writeData(self, filename):
		f = open(filename, 'w')
		f.write(str(self.graph.Order()) + "  " + str(self.graph.Size()) + "\n")
		for node in self.graph.GetNodes():
			cent = self.graph.graph.node[node]["eigcent"]
			pos = self.node_pos(node)
			f.write(node + " " + str(cent) + " " + str(pos.x) + " " + str(pos.y) + "\n")
		self.graph.SetEdgeOrder(EDGE_CENTRALITY)
		for edge in self.graph.GetEdges():
			f.write(edge[0] + " " + edge[1] + "\n")
		f.close

	def WriteIndexFile(self, filename, nodes):
		f = open(filename, 'w')
		for node in nodes:
			# f.write(str(self.graph.graph.node[node]["cgpos"]).ljust(16))
			f.write(self.IndexString(self.graph.graph.node[node]["cgpos"]))
			f.write("\t")			
			# f.write(node.ljust(12)[:12])
			# f.write("\t")			
			name = self.graph.graph.node[node].get("name", "")
			f.write(name.ljust(100)[:100])
			f.write('\n')
		f.close()
		
	def IndexString(self, cgpos):
		x = float(cgpos[1][0])/cgpos[0]
		y = float(cgpos[1][1])/cgpos[0]
		x *= 8
		y *= 8
		x = x + 8
		y = 13 - y
		xlet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[int(math.floor(x))]
		xfrac = x - math.floor(x)
	# 	return xlet + str(xfrac)[1:].ljust(9)[:9] + str(y + 1).ljust(10)[:10]
		return xlet + "\t" + str(int(math.floor(y)))
		# return xlet + str(xfrac)[1:].ljust(9)[:9] + str(y).ljust(10)[:10]


	def SetScale(self, maxbbdim, scale):
		if maxbbdim is not None:
			bbmax = self.grid.GetBBMax()
			self.scale = maxbbdim/bbmax
			print "BBMAX = ", bbmax
			print "maxbbdim = ", maxbbdim
		elif scale is not None:
			self.scale = scale
		print "scale = ", self.scale
		
	def node_pos(self, node):
		return self.grid.NodePos(self.graph.graph.node[node][self.grid.PosName()])
		
	def node_pos_xformed(self, node):
		pos = self.graph.graph.node[node][self.grid.PosName()]
		return self.grid.NodePos(pos) + OffsetVec.scale(self.grid.LayerNum(pos))
		
	def NodePos(self):
		nodes = self.graph.GetNodes()
		return [self.node_pos_xformed(node).scale(self.scale) for node in nodes]
		# keys = [self.graph.graph.node[node]["cgpos"] for node in nodes]
		# return [vector2(float(key[1])/key[0], float(key[2])/key[0]).scale(self.scale) for key in keys]
				
	def EdgePos0(self):
		edges = self.graph.GetEdges()
		return [self.node_pos_xformed(edge[0]).scale(self.scale) for edge in edges]
		# keys = [self.graph.graph.node[edge[0]]["cgpos"] for edge in edges]
		# return [vector2(float(key[1])/key[0], float(key[2])/key[0]).scale(self.scale) for key in keys]
		
	def EdgePos1(self):
		edges = self.graph.GetEdges()
		return [self.node_pos_xformed(edge[1]).scale(self.scale) for edge in edges]
		# return [self.grid.NodePos(self.graph.graph.node[edge[1]][self.grid.PosName()]) for edge in edges]
		# keys = [self.graph.graph.node[edge[1]]["cgpos"] for edge in edges]
		# return [vector2(float(key[1])/key[0], float(key[2])/key[0]).scale(self.scale) for key in keys]
