#!/usr/bin/env python

'''
versiontools.py requires Python 2.3 or later.

It provides functions (variables) that are news since Python 2.4 or later:
	set_type, Set, ImmutableSet, set, frozenset
	any, all
	sorted

It also supply something for Python 3:
	basestring

Usage:
	from versiontools import *

'''

import sys

if sys.version < '2.3':
	print 'Need python version >= 2.3.' # need set
	sys.exit(0)
#elif sys.version < '2.4':
#	from sets import Set as set
#Set = set
set_type = []
try:
	from sets import Set, ImmutableSet # BaseSet
	set_type.extend([Set, ImmutableSet])
except:
	Set, ImmutableSet = set, frozenset
if sys.version < '2.4':
	set, frozenset = Set, ImmutableSet 
else:
	set_type.extend([set, frozenset])

if sys.version < '2.4':
	def sorted(lst, reverse=False):
		lst = list(lst) # convert to list. lst[:]
		lst.sort(reverse=reverse)
		return lst
	def reversed(lst):
		return lst[::-1]

if sys.version < '2.5':
	def any(s):
		for i in s:
			if i: return True
		return False
	def all(s):
		for i in s:
			if not i: return False
		return bool(s)

if sys.version > '3':
	basestring = str

