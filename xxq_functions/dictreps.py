#!/usr/bin/env python

def dictreps(optlist):
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
