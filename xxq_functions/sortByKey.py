#!/usr/bin/env python

'''
sortByKey.py

The purpose is to sort rows by keys of given order.

License: GNU GPL
Author: Dr. Xiao-Qin Xia

Usage:
	sortByKey.py  [options]  parameters

Options:
	-h, --help:	Display this message, then exit
	--version:	Print version information

	-i, --input:	Input file. If not provided, pop the first value in
		{parameters}, or STDIN

	-o, --output:	Output file. If not provided, pop the first value in
		{parameters}, or STDOUT

	-k:	The file containing keys in order.

	-s:	The separator for key. The whole row will be used as the key if not supplied.

parameters:
	Input file, Output file:	If these augments are not provided in Options.

'''

import os, sys
from basetools import exitMsg, InputFile, OutputFile

__version__ = '0.0.1'

def Main(fsrc, fobj, fkey, ksep=None, sep='\t', linesep=os.linesep):
	if not fkey: return
	keys = map(lambda a:a.replace('\r', '').replace('\n', ''), InputFile(fkey))
	keys = dict(zip(keys, range(len(keys)))) # {key:order, ...}
	getkey = ksep and ( lambda a,b=keys,c=len(keys),d=ksep:b.get(a[:a.index(d)], c) ) or ( lambda a,b=keys,c=len(keys):b.get(a, c) )
	src = map(lambda a:a.replace('\r', '').replace('\n', ''), InputFile(fsrc))
	src.sort(key=getkey)
	fobj = OutputFile(fobj)
	map(lambda a,b=fobj:b.write(a + linesep), src)

if __name__ == '__main__':
	from getopt import getopt
	optlst, args = getopt(sys.argv[1:], 'hi:o:k:s:', ['help', 'version', 'input=', 'output='])
	# options that can have multiple values, e.g., '--rep-opt'
	repopts = [] 
	# options that musted be supplied, e.g., ['--must-opt', ('-c', '--col'), ...]
	mustopts = ['-k'] 
	# options that will be automatically dealt with. e.g. [(int, ('-n', '--num'), 'num', 3), ...] -- (type, (option names), target variable names, default values). type can be int, float, str, bool, or any self-defined functions.
	autopts = [(str, '-k', 'fkey', None), (str, '-s', 'ksep', None)] 
	# tuples for options that should have the same length, e.g., ('gene_chr', 'gene_strand', 'gene_file')
	matchopts = [] 
	err = []

	if not repopts:
		optdic = dict(optlst)
	else:
		try:
			from newdicts import RepDict
			optdic = RepDict(optlst)
			for k, v in optdic.items():
				if isinstance(v, list) and k not in repopts:
					err.append('Error: "%s" should be unique, but was provided for %d times' % (k, len(v)))
			# change repopts into list
			for k in repopts:
				if k in optdic and not isinstance(optdic[k], list):
					optdic[k] = [optdic[k]]
		except:
			sys.stderr.write('Warning: the "newdict" module cannot be found! Then only the last value for multiple options ("%s") will be used!' % '", "'.join(repopts))
			optdic = dict(optlst)

	# print help information
	if '-h' in optdic or '--help' in optdic:
		exitMsg(__doc__)
	if '--version' in optdic:
		exitMsg(__file__ + ': ' + __version__)

	# check availability of mandatory options
	if mustopts:
		#mustopts = [opt for opt in mustopts if opt not in optdic]
		needopts = []
		for opt in mustopts:
			if isinstance(opt, (tuple, list)):
				for aopt in opt:
					if aopt in optdic: break
				else:
					needopts.append('" or "'.join(opt))
			else:
				if opt not in optdic:
					needopts.append(opt)
		if needopts:
			err.append('Error - mandatory options ("%s") missing!' % '", "'.join(needopts))

	# auto options
	if autopts:
		_funs = {bool:lambda a,b=optdic:a in b}
		for _tp, _opts, _var, _default in autopts:
			if _tp not in (bool, str, int, float): # add new functions
				_funs[_tp] = _tp			
			_fun = _funs.get(_tp, lambda a,b=optdic:(isinstance(b[a], list) and [map(_tp, b[a])] or [_tp(b[a])])[0]) #_funs.get(_tp, lambda a,b=optdic:_tp(b[a]))
			if not isinstance(_opts, (tuple, list)):
				_opts = [_opts]
			_opts = [_opt for _opt in _opts if _opt in optdic] 
			if len(_opts) > 1: # allow different option names for the same variable
				if len(_opts) > 1: # multiple options names provided
					if _opts[0] not in repopts:
						err.append('Error - options ("%s") should not be supplied simultaneously!' % '", "'.join(_opts))
					else: # allow multiple values!
						_val = []
						map(lambda a,b=_val,c=optdic:b.extend(_fun(c[a])), _opts)
			elif len(_opts) == 0:
				vars()[_var] = _default
			else: # must be 1
				try: # use vars to set new variables.
					vars()[_var] = _fun(_opts[0])
				except:
					err.append('Error - invalid value for option ("%s")' % _opts[0])

	# check options that should be matching
	for opts in matchopts:
		if not opts or not isinstance(opts, (tuple, list)) or len(opts)<=1: continue
		opt0 = optdic.get(opts[0], [])
		ln0 = not isinstance(opt0, (tuple, list)) and 1 or len(opt0)
		for opt in opts[1:]:
			opt1 = optdic.get(opt, [])
			ln1 = not isinstance(opt1, (tuple, list)) and 1 or len(opt1)
			if ln1 != ln0:
				err.append('Error - the numbers of parameters (%s) do not match!' % (', '.join(opts)))
				break

	# specific options can be added over here
	try:
		fsrc = optdic.get('-i', optdic.get('--input', None)) or args.pop(0)
	except: fsrc = sys.stdin
	try:
		fobj = optdic.get('-o', optdic.get('--output', None)) or args.pop(0)
	except: fobj = sys.stdout

	if args:
		err.append('Error - unrecognized parameters:\n\t%s' % ', '.join(args))

	# quit on error
	if err:
		err.append('\n\nPlease type "%s -h " for help.\n' % sys.argv[0])
		exitMsg(err, out=sys.stderr)
	
	# start job
	Main(fsrc, fobj, fkey, ksep=ksep)
	
