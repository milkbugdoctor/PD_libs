#ListDict offer a dictionary in which all keyword keep in sequence, rather than random
try: 
	import paras
	if paras.USE_PSYCO:
		import psyco
		from psyco.classes import *
except: pass

import types, sys

def DeepUpdate(src, obj): # only recurse dictionaries
	if not src: return
	for key, value in src.items():
		if not obj.has_key(key): obj[key]=value
		else:
			if (type(obj[key]) is types.DictType) and (type(value) is types.DictType):
				DeepUpdate(src[key], obj[key])
			elif isinstance(obj[key], CommonDict): obj[key].DeepUpdate(value)
			elif isinstance(value, CommonDict): DeepUpdate(value.dict, obj[key])
			else: obj[key]=value

def DeepCopy(dict): # only recurse dictionaries. Need more study
	if isinstance(dict, CommonDict): return dict.DeepCopy()
	newdict={}
	for key, value in dict.items():
		ktype=type(value)
		if ktype is types.ListType: newdict[key]=value[:] # do not recurse list yet
		elif ktype is types.DictType: newdict[key]=self.DeepCopy(value)
		else: newdict[key]=value
	return newdict


def RepDict(optlist):
	'''Convert a list of tuples into a dict, values for replicated keys are kept in a list.'''
	rlt = {}
	for k, v in optlist:
		if k not in rlt:
			rlt[k] = v
			continue
		vv = rlt[k]
		if isinstance(vv, list):
			vv.append(v)
			continue
		rlt[k] = [vv, v]
	return rlt


class CommonDict:
	"Only offer self.dict"
	def __init__(self, **kw):
		keys=kw.keys()
		if "dict" in keys:
			dict=kw["dict"]
			if type(dict) is types.DictType:
				self.dict=dict.copy()
			elif isinstance(dict, CommonDict):
				self.dict=dict.dict.copy()
		if "dict" not in self.__dict__.keys() or type(self.dict) is not types.DictType:
			self.dict={}

	def __len__(self): return len(self.dict)
	def __getitem__(self, key): return self.dict[key]
	def __setitem__(self, key, value): self.dict[key]=value
	def __delitem__(self, key): del self.dict[key]
	def keys(self): return self.dict.keys()
	def values(self): return self.dict.values()
	def items(self): return self.dict.items()
	def get(self, key, *value): return apply(self.dict.get, (key,)+value)
	def setdefault(self, key, *value): return apply(self.dict.setdefault, (key,)+value)
	def clear(self): self.dict.clear()
	def copy(self): return apply(self.__class__, (), {"dict":self}) #eval(self.__class__.__name+"(self)")
	def has_key(self, key): return self.dict.has_key(key)
	def update(self, dict):
		if type(dict) is types.DictType:
			self.dict.update(dict)
		elif isinstance(dict, CommonDict):
			self.dict.update(dict.dict)
		else: return

	def DeepCopy(self, dict=None): # Need more study
		if dict: return DeepCopy(dict)
		obj=apply(self.__class__, ()) #eval(self.__class__.__name+"()")
		obj.dict=DeepCopy(self.dict)
		return obj

	def DeepUpdate(self, src, obj=None):
		if type(obj) is types.DictType:
			DeepUpdate(src, obj)
		elif isinstance(obj, CommonDict):
			obj.DeepUpdate(src)
		elif obj: return
		DeepUpdate(src, self.dict)

class WildDict(CommonDict):
	"Offer a wild"
	wild=None

	def __init__(self, **kw):
		keys=kw.keys()
		if "dict" in keys:
			dict=kw["dict"]
			if isinstance(dict, WildDict):
				self.dict=dict.dict.copy()
				self.wild=dict.wild
				del kw["dict"]
		if "wild" in keys: self.wild=kw["wild"]
		apply(CommonDict.__init__, (self,), kw)

	def __del__(self):
		self.Remove()

	def Remove(self):
		self.clear()

	def __getitem__(self, key):
		if self.has_key(key): return self.dict[key]
		return self.wild
	def update(self, dict):
		if isinstance(dict, WildDict):
			self.wild=dict.wild
		CommonDict.update(self, dict)

	def Wild(self, *value):
		if not value: return self.wild
		self.wild=value[0]

	def DeepCopy(self, dict=None):
		if dict: return DeepCopy(dict)
		obj=CommonDict.DeepCopy(self, self)
		obj.wild=self.wild
		return obj

	def DeepUpdate(self, src, obj=None):
		CommonDict.DeepUpdate(self, src, obj)
		if obj: return
		if isinstance(src, WildDict): self.wild=src.wild

class ListDict(CommonDict): # Can implement the methods of a list in the future
	"offer a list: self.keylist"
	def __init__(self, **kw):
		keys=kw.keys()
		if "dict" in keys:
			dict=kw["dict"]
			if isinstance(dict, ListDict):
				self.dict=dict.dict.copy()
				self.keylist=dict.keylist[:]
		apply(CommonDict.__init__, (self, ), kw)
		if "keylist" not in self.__dict__.keys() or type(self.keylist) is not types.ListType:
			self.keylist=self.dict.keys()

	def __del__(self):
		self.Remove()

	def Remove(self):
		self.clear()

	# Emulating a dictionary
	#"""
	def __len__(self): return len(self.keylist)
	def __setitem__(self, key, value):
		if not self.dict.has_key(key): self.keylist.append(key)
		self.dict[key]=value
	def __delitem__(self, key):
		del self.dict[key]
		self.keylist.remove(key)
	def keys(self): return self.keylist[:]
	def values(self):
		vl=[]
		for k in self.keylist: vl.append(self.dict[k])
		return vl
	def items(self): #return self.dict.items()
		vl=[]
		for k in self.keylist: vl.append((k, self.dict[k]))
		return vl
	def setdefault(self, key, *value):
		if key not in self.keylist and value: self.keylist.append(key)
		return apply(self.dict.setdefault, (key,)+value)
	def clear(self):
		self.keylist[:]=[]
		self.dict.clear()
	def copy(self): return apply(self.__class__, (), {"dict":self}) #eval(self.__class__.__name+"(self)")
	def has_key(self, key):
		if key in self.keylist: return 1
		return 0
	def update(self, dict): #Keep my sequence, but use the value from dict
		CommonDict.update(self, dict)
		if type(dict) is types.DictType:
			keys=dict.keys()
		elif isinstance(dict, ListDict):
			keys=dict.keylist
		elif isinstance(dict, CommonDict):
			keys=dict.dict.keys()
		else: return
		for k in keys:
			if k not in self.keylist: self.keylist.apend(k)
	def sort(self, template=None): # wait to complete
		if template is None: return self.keylist.sort()
		old_sites	= [] #ListDict()
		for k in template:
			if self.has_key(k): old_sites.append(self.keylist.index(k)) #nd[k] = self.keylist.index(k)
		if not old_sites: return
		new_sites = old_sites[:]
		if sys.version >= "2.2":
			site_dict = dict(zip(new_sites, old_sites))
		else:
			site_dict = {}
			for i in range(len(new_sites)):
				site_dict[new_sites[i]] = old_sites[i]
		current_site = start_site = new_sites[0]
		start_value = self.keylist[start_site]
		while 1:
			next_site = site_dict[current_site]
			if next_site == start_site:
				self.keylist[current_site] = start_value
				break
			self.keylist[current_site] = self.keylist[next_site]
		return

	def DeepCopy(self, dict=None):
		if dict: return DeepCopy(dict)
		obj=CommonDict.DeepCopy(self, self)
		obj.keylist=self.keylist[:]
		return obj

	def DeepUpdate(self, src, obj=None):
		CommonDict.DeepUpdate(self, src, obj)
		if obj: return

		dict = src
		if type(dict) is types.DictType:
			keys=dict.keys()
		elif isinstance(dict, ListDict):
			keys=dict.keylist
		elif isinstance(dict, CommonDict):
			keys=dict.dict.keys()
		else: return
		for k in keys:
			if k not in self.keylist: self.keylist.append(k)

	def AbsorbSeq(self, seq=[]):
		for k,v in seq: 
			if not self.dict.has_key(k): self.keylist.append(k)
			self.dict[k] = v

class WildListDict(ListDict, WildDict):
	"offer keylist and wild"
	def __init__(self, **kw):
		apply(ListDict.__init__,(self,), kw)
		keys=kw.keys()
		if "dict" in keys:
			dict=kw["dict"]
			if isinstance(dict, WildDict): self.wild=dict.wild
			del kw["dict"]
		apply(WildDict.__init__,(self,), kw)

	def __getitem__(self, key):
		if key in self.keylist: return self.dict[key]
		return self.wild
	def copy(self): return apply(self.__class__, (), {"dict":self}) #eval(self.__class__.__name+"(self)")
	def update(self, dict):
		ListDict.update(self, dict)
		if isinstance(dict, WildDict):
			self.wild=dict.wild

	def DeepCopy(self, dict=None): # Need more study
		obj=ListDict.DeepCopy(self, dict)
		if isinstance(obj, WildDict):
			obj.wild=self.wild
		return obj

	def DeepUpdate(self, src, obj=None):
		ListDict.DeepUpdate(src, obj)
		if not obj and isinstance(src, WildDict):
			self.wild=src.wild

try:
	if paras.USE_PSYCO:
		for k in globals().values():
			if type(k) in [types.FunctionType, types.ClassType]:
				psyco.bind(k)
except: pass

			
