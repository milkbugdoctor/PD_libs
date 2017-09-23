#!/usr/bin/env python

'''
The purpose is to find tiling probes from results of WebArrayDB transposon analysis.

Usage:
	python findTilingProbesAt.py  [options]  parameters

Options:
	-h, --help:	Display this message, then exit
	-i, --input:	Input file. If not provided, pop the first value in {parameters}, or STDIN
	-o, --output:	Output file. If not provided, pop the first value in {parameters}, or STDOUT
	--version:	Print version information

	-t:	Tiling file (WebArrayDB transposon analysis result)
	-n: Number of tiling probes to be find. The default is 5
	--chr:	chromosome name in the col-chr column of the input name
	--col-chr, --col-strand, --col-start, --col-end: Column names in the input file. the default are chromosome, strand, probe_start, probe_end
	--group1, --group2:	The numbers of columns names of intensity values for group 1, and group 2 in the tiling file
	--threshold: "present" or "absent" is judged by the threshold of the difference ratio of median A (island) versus total A 

	--single-row: A switch. If provided, multiple matches will be output in a single row.

parameters:
	Input file, Output file:	If these augments are not provided in Options
'''

import os, sys
from basetools import exitMsg, TableFile
from bisect import bisect, bisect_left, bisect_right
import numpy

__version__ = '0.0.1'

def readTilingProbes(ftile, group1, group2):
	'''
	ftile: WebArrayDB transposon analysis result file, with columns: unique_id, probe_strand, probe_start, probe_end
	return: {'+':[(end, start, (unique_id, M, A, ch1, ch2, ...)), ...], '-':[...], '':[...]} # end should be smaller than start on '-' strand.
	'''
	ftile = TableFile(ftile)
	head = ftile.next()
	#i_idx, i_strand, i_start, i_end, i_M, i_A, i_ch1, i_ch2 =
	if 'unique_id' not in head and 'id' in head:
		head[head.index('id')] = 'unique_id'
	i_cols = map(head.index, ('unique_id', 'probe_strand', 'probe_start', 'probe_end', 'M', 'A'))
	#i_chs = range(head.index('A')+1, head.index('idx')) # the columns between 'A' and 'idx' are channels
	i_chs = range(i_cols[-1]+1, i_cols[-1]+1+group1+group2) # the columns after 'A'
	rlt = {} #'+':[], '-':[], '':[]}
	for line in ftile:
		unique_id, strand, start, end, M, A = map(line.__getitem__, i_cols)
		#start, end, I_group1, I_group2 = int(start), int(end), float(I_group1), float(I_group2)
		chs = map(line.__getitem__, i_chs)
		try: start = int(start)
		except: 
			try: start = int(end)
			except: start = 0
		try: end = int(end)
		except: end = start
		try: M = float(M)
		except: M = 0
		try: A = float(A)
		except: A = 0
		if start > end: start, end = end, start
		if strand == '-': start, end = end, start
		for i in range(len(chs)):
			try: chs[i] = float(chs[i])
			except: chs[i] = 0
		v = (unique_id, M, A) + tuple(chs)
		rlt.setdefault(strand, []).append((end, start, v))
		rlt.setdefault(strand+'rev', []).append((start, end, v))
	for v in rlt.values(): v.sort() # sort it
	return rlt

def Main(fsrc, fobj, ftile, chr_name, group1=1, group2=1, n_probes=5, col_chr='chromosome', col_strand='strand', col_start='probe_start', col_end='probe_end', threshold=1, single_row=False, sep='\t', linesep=os.linesep, join_str=' /// '):
	'''
	fsrc: a file with columns for col_chr, col_strand, col_start, col_end
	ftile: WebArrayDB transposon analysis result file, with columns: unique_id, probe_strand, probe_start, probe_end, M, A
	chr_name: the chromosome name related to the specific ftile. (chromosome and plasmid are separated in WebArrayDB analysis!)
	'''
	# read Tn result first
	probes = readTilingProbes(ftile, group1, group2) # {'+':[(end, start, (unique_id, M, A, I_gropu1, I_group2)), ...], '-':[], '':[]} # end should be smaller than start on '-' strand.
	pbs_pos = probes.get('+', [])
	pbs_pos_rev = probes.get('+rev', [])
	pbs_neg = probes.get('-', [])
	pbs_neg_rev = probes.get('-rev', [])
	ln_pos, ln_neg = len(pbs_pos), len(pbs_neg)
	# get the general median of intensity values for group1 and group2
	#median1 = numpy.median(map(lambda a:a[2][3], pbs_pos) + map(lambda a:a[2][3], pbs_neg))
	#median2 = numpy.median(map(lambda a:a[2][4], pbs_pos) + map(lambda a:a[2][4], pbs_neg))
	valtmp = []
	map(lambda a,b=valtmp:b.extend(a[2][3:3+group1]), pbs_pos)
	map(lambda a,b=valtmp:b.extend(a[2][3:3+group1]), pbs_neg)
	median1 = numpy.median(valtmp)
	del valtmp[:]
	map(lambda a,b=valtmp:b.extend(a[2][3+group1:3+group1+group2]), pbs_pos)
	map(lambda a,b=valtmp:b.extend(a[2][3+group1:3+group1+group2]), pbs_neg)
	median2 = numpy.median(valtmp)

	fsrc = TableFile(fsrc)
	head = fsrc.next()
	i_chr, i_strand, i_start, i_end = i_cols = map(head.index, (col_chr, col_strand, col_start, col_end))
	col_rlts = (
			'unique_id (+)', 'tuple median of M (+)', 'tuple median (group1, +)', 'tuple median (group2, +)', 'tuple median (group1, +) - general median', 'tuple median (group2, +) - general median', 'island regulation (group1/group2, +)', 'signal call (group1, +)', 'signal call (group2, +)', # 0-8
			'unique_id (-)', 'tuple median of M (-)', 'tuple median (group1, -)', 'tuple median (group2, -)', 'tuple median (group1, -) - general median', 'tuple median (group2, -) - general median', 'island regulation (group1/group2, -)', 'signal call (group1, -)', 'signal call (group2, -)' # 9-17
			) 
	for colnm in col_rlts:
		if colnm not in head: head.append(colnm)
	i_rlts = dict(zip(col_rlts, map(head.index, col_rlts)))
	n_col = len(head)
	fobj = isinstance(fobj, str) and open(fobj, 'w') or fobj
	fobj.write(sep.join(head) + linesep)
	# end, start, (unique_id, M, A, I_group1, I_group2))
	#dtlist = [('unique_id', '|S10'), ('M', float), ('A', float)] #, ('I_group1', float), ('I_group2', float)]
	#dtlist.extend(map(lambda i:('ch_'+str(i), float), range(1, 1+group1+group2)))
	for line in fsrc:
		n_dif =  n_col - len(line)
		if n_dif > 0: line.extend(['']*n_dif)
		chrs, strands, starts, ends = map(lambda a:a.split(join_str), map(line.__getitem__, i_cols))
		vals = []
		for chr, strand, start, end in zip(chrs, strands, starts, ends):
			if chr != chr_name: continue # skip other chromosomes
			start, end = int(start), int(end)
			if start > end: start, end = end, start
			if strand == '-':
				start, end = end, start
				loc = bisect(pbs_neg, (end, ))  
				if loc > 0 and pbs_neg[loc-1][1] > end: loc -= 1 # check the overlapping tile
				secs_neg = loc >= ln_neg-n_probes and pbs_neg[loc:] + pbs_neg[:n_probes-(loc-ln_neg)] or pbs_neg[loc:loc+n_probes]
				loc = bisect(pbs_pos_rev, (end, ))  
				if loc > 0 and pbs_pos_rev[loc-1][1] > end: loc -= 1 # check the overlapping tile
				secs_pos = loc >= ln_pos-n_probes and pbs_pos_rev[loc:] + pbs_pos_rev[:n_probes-(loc-ln_neg)] or pbs_pos_rev[loc:loc+n_probes]
			else: # positive strand
				loc = bisect(pbs_pos, (end, ()))  
				if loc < ln_pos and pbs_pos[loc][1] < end: loc += 1 # check the overlapping tile
				secs_pos = loc >= n_probes and pbs_pos[loc-n_probes:loc] or pbs_pos[-1:-(n_probes+1-loc)] + pbs_pos[:loc]
				loc = bisect(pbs_neg_rev, (end, ()))
				if loc < ln_neg and pbs_neg_rev[loc][1] < end: loc += 1 # check the overlapping tile
				secs_neg = loc >= n_probes and pbs_neg_rev[loc-n_probes:loc] or pbs_pos[-1:-(n_probes+1-loc)] + pbs_pos[:loc]
			val = []
			if single_row:
				for secs in (secs_pos, secs_neg):
					#ln = max(map(lambda a:len(a[2][0]), secs)) # get max len of unique_id
					#dtlist[0] = ('unique_id', '|S%d' % ln)
					#DT = numpy.array(map(lambda a:a[2], secs), dtype=dtlist)
					#ids = ', '.join(DT['unique_id'])
					#mM = numpy.median(filter(bool, DT['M'])) # filter out values 0, which is converted from NA
					#m1, m2 = numpy.median(DT['I_group1']), numpy.median(DT['I_group2'])
					
					ids = ', '.join(map(lambda a:a[2][0], secs))
					DT = numpy.array(map(lambda a:a[2][1:], secs))
					mM = numpy.median(filter(bool, DT[:,0]))
					m1, m2 = numpy.median(DT[:, 2:2+group1]), numpy.median(DT[:, 2+group1:2+group1+group2])

					dm1, dm2 = m1 - median1, m2 - median2
					sM, s1, s2 = mM < -1 and -1 or mM > 1 and 1 or 0, dm1 > threshold and 'present' or 'absent', dm2 > threshold and 'present' or 'absent'
					val.extend([ids, mM, m1, m2, dm1, dm2, sM, s1, s2])
				vals.append(map(str, val))
			else:
				for secpair in zip(secs_pos, secs_neg):
					vsp = []
					for s in secpair:
						s = s[2]
						ids, mM = s[0], s[1], 
						m1, m2 = numpy.median(s[2:2+group1]), numpy.median(s[2+group1:2+group1+group2])
						dm1, dm2 = m1 - median1, m2 - median2
						sM, s1, s2 = mM < -1 and -1 or mM > 1 and 1 or 0, dm1 > threshold and 'present' or 'absent', dm2 > threshold and 'present' or 'absent'
						vsp.extend([ids, mM, m1, m2, dm1, dm2, sM, s1, s2])
					val.append(map(str, vsp))
				vals.extend(val)
		ln = len(vals)
		if single_row or ln == 0:
			if ln > 0:
				if ln > 1:
					vals = numpy.array(vals)
					vals = map(lambda a:join_str.join(vals[:,a]), range(vals.shape[1]))
				elif ln == 1:
					vals = vals[0]
				for i in range(len(vals)):
					j = i_rlts[col_rlts[i]]
					if not line[j].strip():
						line[j] = vals[i]
					else:
						line[j] = line[j] + join_str + vals[i]
			fobj.write(sep.join(line) + linesep)
		else:
			for val in vals:
				linetmp = line[:]
				for i in range(len(val)):
					j = i_rlts[col_rlts[i]]
					if not linetmp[j].strip():
						linetmp[j] = val[i]
					else:
						linetmp[j] = linetmp[j] + join_str + val[i]
				fobj.write(sep.join(linetmp) + linesep)
			

if __name__ == '__main__':
	from getopt import getopt
	optlst, args = getopt(sys.argv[1:], 'hi:o:t:n:', ['help', 'version', 'input=', 'output=', 'chr=', 'col-chr=', 'col-strand=', 'col-start=', 'col-end=', 'group1=', 'group2=', 'threshold=', 'single-row'])
	repopts = [] # options that can have multiple values, e.g., '--rep-opt'
	mustopts = ['-t', '--chr'] # options that musted be supplied, e.g., '--must-opt'
	autopts = [(str, '-t', 'ftile', ''), (int, '-n', 'n_probes', 5), (str, '--chr', 'chr', ''), (str, '--col-chr', 'col_chr', 'chromosome'), (str, '--col-strand', 'col_strand', 'strand'), (str, '--col-start', 'col_start', 'probe_start'), (str, '--col-end', 'col_end', 'probe_end'), (int, '--group1', 'group1', 1), (int, '--group2', 'group2', 1), (int, '--threshold', 'threshold', 1), (bool, '--single-row', 'single_row', False)] # options that will be automatically dealt with. e.g. [(int, ('-n', '--num'), 'num', 3), ...] -- (type, (option names), target variable names, default values). type can be int, float, str, or bool.
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
	Main(fsrc, fobj, ftile, chr, group1=group1, group2=group2, n_probes=n_probes, col_chr=col_chr, col_strand=col_strand, col_start=col_start, col_end=col_end, threshold=threshold, single_row=single_row)
	
