#!/usr/bin/env python

'''
The purpose is to add tails to specific colnames

Usage:
	python addColTail.py  [options]  parameters

Options:
	-h, --help:	Display this message, then exit
	--version:	Print version information

	-i, --input:	Input file, or STDIN
	-o, --output:	Output file, or STDOUT

	--sep: the sep string between orignal column name and tail
	--no-enclose: don't use parenthesys to enclose tails

parameters:
	Tails to be added to column names.
'''

import os, sys, re
from basetools import exitMsg

__version__ = '0.0.1'

cols = ['tuple median of M', 'tuple median (group1)', 'tuple median (group2)', 'tuple median (group1) - general median', 'tuple median (group2) - general median', 'island regulation (group1/group2)', 'signal call (group1)', 'signal call (group2)', 'M', 'A', re.compile(r'[^\t]+\.[1-9]$')] #, re.compile(r'[^\t]+\.[1-9]$')]

def Main(fsrc, fobj, cols=cols, tails=[], sep_str=' ', enclose=True, sep='\t', linesep=os.linesep):
	fsrc = isinstance(fsrc, str) and open(fsrc) or fsrc
	head = fsrc.readline().replace('\r', '').replace('\n', '').split(sep)
	ln = len(head)
	rng = range(ln)
	if enclose: tails = map(lambda a:'('+a+')', tails)
	for tail in tails:
		for col in cols:
			if isinstance(col, str):
				if col in head:
					i = head.index(col)
					head[i] = head[i] + sep_str + tail
			else: # must be a re object
				for i in rng: # change the first occurrence
					m = col.match(head[i])
					if m:
						head[i] = head[i] + sep_str + tail
						break
				while i < ln-1: # change other adjacent occurrences
					i = i + 1
					m = col.match(head[i])
					if not m: break
					head[i] = head[i] + sep_str + tail
	fobj = isinstance(fobj, str) and open(fobj, 'w') or fobj
	fobj.write(sep.join(head) + linesep)
	for line in fsrc: fobj.write(line)

if __name__ == '__main__':
	from getopt import getopt
	optlst, args = getopt(sys.argv[1:], 'hi:o:', ['help', 'version', 'input=', 'output=', 'sep=', 'enclose'])
	repopts = [] # options that can have multiple values, e.g., '--rep-opt'
	mustopts = [] # options that musted be supplied, e.g., '--must-opt'
	autopts = [(str, '--sep', 'sep_str', ' '), (bool, '--no-enclose', 'no_enclose', False)] # options that will be automatically dealt with. e.g. [(int, ('-n', '--num'), 'num', 3), ...] -- (type, (option names), target variable names, default values). type can be int, float, str, or bool.
	matchopts = [] # tuples for options that should have the same length, e.g., ('gene_chr', 'gene_strand', 'gene_file')
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
		mustopts = [opt for opt in mustopts if opt not in optdic]
		if mustopts:
			err.append('Error - mandatory options ("%s") missing!' % '", "'.join(mustopts))

	# auto options
	if autopts:
		_funs = {bool:lambda a,b=optdic:a in b}
		for _tp, _opts, _var, _default in autopts:
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
	fsrc = optdic.get('-i', optdic.get('--input', None)) or sys.stdin
	fobj = optdic.get('-o', optdic.get('--output', None)) or sys.stdout

	if not args:
		err.append('Error - no tail provided')

	# quit on error
	if err:
		err.append('\n\nPlease type "%s -h " for help.\n' % sys.argv[0])
		exitMsg(err, out=sys.stderr)
	
	# start job
	enclose = not no_enclose
	Main(fsrc, fobj, tails=args, sep_str=sep_str, enclose=enclose)
	
