#!/usr/bin/env python

'''
fa2phy.py

Convert an aligned sequence file in FASTA format Phylip format

License: GNU GPL
Author: Dr. Xiao-Qin Xia

Usage:
	fa2phy.py  [options]  parameters

Options:
	-h, --help:	Display this message, then exit
	--version:	Print version information

	-i, --input:	Input file. If not provided, pop the first value in
		{parameters}, or STDIN

	-o, --output:	Output file. If not provided, pop the first value in
		{parameters}, or STDOUT

	--name-len: The maximal length of a taxon name. The default is no limitation

	--map-file: The file with columns 

	--remove-replicates: Optional, remove replicate names.

parameters:
	Input file, Output file:	If these augments are not provided in Options.

'''

import os, sys, re
from basetools import exitMsg, TableFile
from seqtools import readGenomes

__version__ = '0.0.1'

def readMaps(fmap):
	'''
	fmap: a Tab-delimited file with columns "No" and "FileName"
	return a dict like { No:ObjName, ...}
	'''
	rlt = {} # { No:{(loc_start, loc_end):Locus_tag, ...}, ...}
	rs = re.compile(r'[\s:,;()[\]]') # char invalid for Newick
	c_No, c_File = 'No', 'Object'
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
		rlt[No] = rs.sub('_', File)
	return rlt

def Main(fsrc, fobj, fmap=None, name_len=None, rm_reps=False, sep='\t', linesep=os.linesep):
	'''
	fsrc: a file of aligned sequneces in FASTA format. The title row should be in format as ">No[:XXX-YYY[:[ZZZ] +|-]]"
	fobj: a file of aligned sequneces in PHYLIP format
	'''
	#r = re.compile(r'(\d+)(:(\d+)-(\d+):(.*)\s+([+-]))?\s*$') # r.match(s).groups(): (No, all_except_No, start, end, Locus_tag, strand)
	r = re.compile(r'(\d+)(:(\d+)-(\d+):(.*)\s+([+-])(,\s+([+-]))?)?\s*$') # r.match(s).groups(): (No, all_except_No, start, end, Locus_tag, strand)
	rs = re.compile(r'[\s:,;()[\]]') # char invalid for RAxML (raxmlHPC)
	minln = name_len or 10
	fmap = fmap and readMaps(fmap) or {}
	seqs = readGenomes(fsrc, title=True, short_title=False) # [(nm, seq), ...]
	# remove seq only with '-'
	seqs = filter(lambda a:a[1].replace('-', '').replace('?', ''), seqs) 
	fobj = isinstance(fobj, str) and open(fobj, 'w') or fobj
	if not rm_reps:
		fobj.write('%d %d\n' % (len(seqs), len(seqs[0][1])))
	else:
		nms = {}
		rlt = []
	for nm, seq in seqs:
		m = r.match(nm)
		if m: # convert to the format: 'No_ID'
			vs = m.groups()
			nm = vs[0]
			if nm in fmap:
				nm = fmap[nm] 
			elif vs[4]: # locus_tag
				nm = nm + '_' + vs[4]

		# convert to 10 char long
		#nm = nm[:10] # keep the first 10 character
		if name_len: nm = nm[:name_len]

		# normalize name
		nm = rs.sub('_', nm) # replace irregular char with '_'
		ln = len(nm)
		if ln < minln:
			nm = nm + (' '*(minln-ln))
		if rm_reps:
			if nm not in nms:
				nms[nm] = True
				rlt.append((nm, seq))
		else:
			fobj.write(nm + ' ' + seq + '\n')
	if rm_reps: #seqs:
		fobj.write('%d %d\n' % (len(rlt), len(rlt[0][1])))
		for nm, seq in rlt:	
			fobj.write(nm + ' ' + seq + '\n')

if __name__ == '__main__':
	from getopt import getopt
	optlst, args = getopt(sys.argv[1:], 'hi:o:', ['help', 'version', 'input=', 'output=', 'map-file=', 'name-len=', 'remove-replicates'])
	repopts = [] # options that can have multiple values, e.g., '--rep-opt'
	mustopts = [] # options that musted be supplied, e.g., '--must-opt'
	# options that will be automatically dealt with. e.g. [(int, ('-n', '--num'), 'num', 3), ...] -- (type, (option names), target variable names, default values). type can be int, float, str, or bool.
	autopts = [(str, '--map-file', 'fmap', ''), (int, '--name-len', 'name_len', None), (bool, '--remove-replicates', 'rm_reps', False)] 
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
	Main(fsrc, fobj, fmap=fmap, name_len=name_len, rm_reps=rm_reps)
	
