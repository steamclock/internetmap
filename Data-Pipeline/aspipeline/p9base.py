
import math
import random

GlobalSeed = 0

def globalSeed(seed):
	global GlobalSeed
	GlobalSeed = seed
	# print "GlobalSeed = ", GlobalSeed
	

class RGen:
	def __init__(self, seed):
		self.seed(seed)
		
	def seed(self, seed):
		# print "seed = ", seed
		# print "GlobalSeed = ", GlobalSeed
		fullseed = seed | (GlobalSeed << 16)
		# print "initing with", fullseed
		random.seed(fullseed)
		self.state = random.getstate()
	
	def random(self, range=1.0):
		random.setstate(self.state)
		value = random.random()*range
		self.state = random.getstate()
		return value

	def randint(self, a, b):
		random.setstate(self.state)
		value = random.randint(a, b)
		self.state = random.getstate()
		return value

	def randrange(self, a, b = None):
		random.setstate(self.state)
		value = random.randrange(a, b)
		self.state = random.getstate()
		return value
		
	def uniform(self, a, b):
		random.setstate(self.state)
		value = random.uniform(a, b)
		self.state = random.getstate()
		return value
		
	def shuffle(self, list):
		random.shuffle(list, self.random)

class vector2(object):
	def __init__(self, x, y):
		self.x = x
		self.y = y
		
	def r(self):
		return self.length()
	
	def a(self):
		return math.atan2(self.y, self.x)

	def __add__(self, other):
		return vector2(self.x + other.x, self.y + other.y)
		
	def __sub__(self, other):
		return vector2(self.x - other.x, self.y - other.y)
		
	def scale(self, fac):
		return vector2(self.x*fac, self.y*fac)
		
	def scale2(self, fac):
		return vector2(self.x*fac.x, self.y*fac.y)
		
	def length(self):
		return math.sqrt(self.x*self.x + self.y*self.y)
		
	def dot(self, other):
		return self.x*other.x + self.y*other.y
	
	def __str__(self):
		return "(" + str(self.x) + ", " + str(self.y) + ")"

	def __repr__(self):
		return "vector2(" + str(self.x) + ", " + str(self.y) + ")"

	def __neg__(self):
		return vector2(-self.x, -self.y)
		
	def __abs__(self):
		return self.length()
		
	def __eq__(self, other):
		return (self.x == other.x) and (self.y == other.y)

def polar2(a, d):
	v = vector2(d*math.cos(a), d*math.sin(a))
	# print "polar2 ", v
	return v
		
def mm(x):
	return x*2.83464567

def cm(x):
	return x*28.3464567

def inches(x):
	return x*72

def feet(x):
	return x*72*12
	
def cubicbezier1(p0, p1, p2, p3, t):
	return p0*(pow(1 - t, 3)) + p1*(3*pow(1 - t, 2)*t) + p2*(3*(1 - t)*pow(t, 2)) + p3*(pow(t, 3))

def cubicbezier2(p0, p1, p2, p3, t):
	return p0.scale(pow(1 - t, 3)) + p1.scale(3*pow(1 - t, 2)*t) + p2.scale(3*(1 - t)*pow(t, 2)) + p3.scale(pow(t, 3))

# page sizes

# p11x17
# A4

PI = 3.14159265
TWOPI = 2*3.14159265
PHI = 1.61803399
INVPHI = 0.61803399


def landscape(v):
	if v.y > v.x:
		return vector2(v.y, v.x)
	return v

def portrait(v):
	if v.y < v.x:
		return vector2(v.y, v.x)
	return v

def square(x):
	return vector2(x, x)

def deg(x):
	return x*3.14159/180.0	

