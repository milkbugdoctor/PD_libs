#!/usr/bin/env python

'''
provide basic tools for table-like file operations
'''

import os, sys, re

class NoColumnError(Exception):
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return repr(self.value)

def splitStr(s, width=70):
	return re.findall(r'.{1,%d}' % width, s)
# or splitStr = lambda s, width=70: [s[i:i+width] for i in range(0, len(s), width)]

def readTable(fp, sep='\t'):
	return map(lambda line:line.replace('\r', '').replace('\n', '').split(sep), isinstance(fp, str) and open(fp) or fp)

def writeTable(fp, tb, sep='\t'):
	if isinstance(fp, str):
		fp = open(fp, 'w')
	for line in tb:
		fp.write('%s\n' % sep.join(line))
	
def TableFile(fp, sep='\t', fix_len=False): # for read only
	'''fix_len:	make all rows has the same number of fields as the first row'''
	fp = isinstance(fp, str) and open(fp) or fp
	ln = None
	for line in fp:
		line = line.replace('\n', '').replace('\r', '').split(sep)
		if fix_len:
			ln1 = len(line)
			if ln is None:
				ln = ln1
			elif ln1 != ln:
				if ln1 > ln:
					line = line[:ln]
				else:
					line.extend(['']*(ln-ln1))
		yield line

def exitMsg(s=None, out=sys.stdout):
	#print __doc__
	if s:
		f = isinstance(out, str) and open(out, 'w') or out
		if isinstance(s, str):
			f.write(s) #print >> f, s
		else:
			#print '\n'.join(s)
			#for row in s:
			#	print >> f, row
			f.write('\n'.join(s))
	sys.exit(0)

exitUsage = exitMsg

def repExt(path, ext):
	return os.path.splitext(path)[0] + ext

def unique(lst):
	'''
	Return a list with unique elements
	'''
	unidic = {}
	unilst = []
	for k in lst:
		if k not in unidic:
			unidic[k] = True
			unilst.append(k)
	return(unilst)

def expandStr(s, sep='-', ret_str=True, intrng=re.compile(r'^\s*(\d+)\s*-\s*(\d+)\s*$')): # intrng.match(s).groups()
	'''
	expand "int1-int2" into a list of integers from int1 to int2.
	s: A string
	return a list of integer or string (determined by ret_str)
	This function is normaly called by expandList, which is used to parse command parameters.
	'''
	m = intrng.match(s)
	if not m: return([s])
	i1, i2 = map(int, m.groups())
	if i1 > i2: i1, i2 = i2, i1
	rlt = range(i1, i2+1)
	if ret_str: rlt = map(str, rlt)
	return(rlt)
	# old version not based on re
	nsep = s.count(sep)
	if nsep != 1: 
		return [s]
	rlt = s.split(sep) # len(rlt) must be 2
	if sep not in s: rlt = [s]
	else:
		try:
			s = map(lambda a:int(a.strip()), s.split(sep))
		except: exitMsg('Failed to convert indexes (%s) to integers!' % s, out=sys.stderr)
		if len(s) != 2 or s[0] > s[1]: exitMsg('Wrong in length of indexes (%s)!' % s, out=sys.stderr)
		rlt = range(s[0], s[1]+1)
		if ret_str: rlt = map(str, rlt)
	return rlt

def expandList(seqs):
	'''
	seqs: can be a string or a list/tuple of such strings, with elements as integers,
		strings. Any element as "int1-int2" will be expand to a list of integers
		from int1 to int2.  
	''' 
	if isinstance(seqs, str): return expandStr(seqs)
	rlt =  []
	map(rlt.extend, map(expandStr, seqs))
	return(rlt)

def InputFile(fn):
	return isinstance(fn, str) and open(fn) or sys.stdin

def OutputFile(fn):
	return isinstance(fn, str) and open(fn, 'w') or sys.stdout


