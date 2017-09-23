#!/usr/bin/env python

'''
addLocusTag4Rows.py

The purpose is to add missing Locus_tag for the ID row in a text file.

License: GNU GPL
Author: Dr. Xiao-Qin Xia

Usage:
	addLocusTag4Rows.py  [options]  parameters

Options:
	-h, --help:	Display this message, then exit
	--version:	Print version information

	-i, --input:	Input file. If not provided, pop the first
		value in {parameters}, or STDIN
	-o, --output:	Output file. If not provided, pop the first
		value in {parameters}, or STDOUT

	--map-file:	The map file contains columns "No" and "FileName". "No" is the
		bacteria strain ID in the ID row of the inputing FASTA file, "FileName"
		is the file name that containing a column "Feature ID" as the
		Loucus_tag.

parameters:
	Input file, Output file:	If these augments are not provided in Options.

'''

import os, sys, re
from basetools import TableFile, exitMsg 

__version__ = '0.0.1'

def readOneMap(fmap):
	'''
	fmap: a Tab-delimited file with columns: 'Feature ID', 'Start', 'Stop', 'Strand'
	return a dict like {(loc_start, loc_end):Locus_tag, ...}, in which Locus_tag comes from the "Feature ID" column.
	'''
	rlt = {} # {(loc_start, loc_end):Locus_tag, ...}
	c_cols = c_Locus, c_Start, c_End, c_Strand = 'Feature ID', 'Start', 'Stop', 'Strand'
	flocus = TableFile(fmap)
	head = flocus.next()
	i_cols = map(head.index, c_cols)
	i_max = max(i_cols) + 1
	for line in flocus:
		if len(line) < i_max:
			line.extend(['']*(i_max - len(line)))
		locus, start, end, strand = map(line.__getitem__, i_cols)
		if '|' in locus: # remove leading "fig|" or "fid|"
			locus = locus[locus.index('|')+1:]
		start, end = int(start), int(end)
		if start > end: # let start <= end
			start, end = end, start
		rlt[(start, end)] = locus
	return rlt

def readMaps(fmap):
	'''
	fmap: a Tab-delimited file with columns "No" and "FileName"
	return a dict like { No:{(loc_start, loc_end):Locus_tag, ...}, ...}
	'''
	rlt = {} # { No:{(loc_start, loc_end):Locus_tag, ...}, ...}
	c_No, c_File = 'No', 'FileName'
	fmap = TableFile(fmap)
	head = fmap.next()
	if c_No not in head or c_File not in head: 
		return rlt
	i_No, i_File = head.index(c_No), head.index(c_File)
	i_max = max(i_No, i_File) + 1
	for line in fmap:
		if len(line) < i_max: 
			line.extend(['']*(i_max-len(line)))
		No, File = line[i_No], line[i_File]
		if os.path.exists(File):
			rlt[No] = readOneMap(File)
	return rlt

def Main(fsrc, fobj, fmap, sep='\t', linesep=os.linesep):
	'''
	fsrc: a file in FASTA format. The title row should be in format as ">No[:XXX-YYY[:[ZZZ] +|-]]"
	fobj: a file in FASTA format, with missing locus_tag added to the ID row (as ZZZ above)
	'''
	r = re.compile(r'(\d+)::(\d+)-(\d+)') # r.match(s).groups(): (No, start, end)
	fsrc = isinstance(fsrc, str) and open(fsrc) or fsrc
	fobj = isinstance(fobj, str) and open(fobj, 'w') or fobj
	fmap = readMaps(fmap)
	def repl(m, d=fmap):
		No, start, end = vs = m.groups()
		start, end = int(start), int(end)
		if start > end: start, end = end, start
		locus = d.get(No, {}).get((start, end), '')
		line = '%s:%s:%s-%s' % (No, locus, vs[1], vs[2])
		return line
	for line in fsrc:
		line = r.sub(repl, line)
		fobj.write(line)

if __name__ == '__main__':
	from getopt import getopt
	optlst, args = getopt(sys.argv[1:], 'hi:o:', ['help', 'version', 'input=', 'output=', 'map-file='])
	repopts = [] # options that can have multiple values, e.g., '--rep-opt'
	mustopts = ['--map-file'] # options that musted be supplied, e.g., '--must-opt'
	autopts = [(str, '--map-file', 'fmap', '')] # options that will be automatically dealt with. e.g. [(int, ('-n', '--num'), 'num', 3), ...] -- (type, (option names), target variable names, default values). type can be int, float, str, or bool.
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
	Main(fsrc, fobj, fmap)
	
