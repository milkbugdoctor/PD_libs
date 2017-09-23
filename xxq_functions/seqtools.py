#!/usr/bin/env python

'''
This file defined some common functions that can be used for generic purposes in sequence analysis.
'''

import string, re
from versiontools import *
from basetools import TableFile, NoColumnError

def readFnaSeqs(fn, keep_anno=False):  # actually similar to readGenomes
	'''
	Read seq_ids and sequences in a FASTA file
	Return a list of tuples: (id, sequence), in which id will keep the leading characyter '>'
	'''
	seqs = []
	seqid = None
	seq = []
	fp = isinstance(fn, basestring) and open(fn) or fn
	for line in fp:
		line = line.strip()
		if line.startswith(';'): # annotation
			continue
		if line.startswith('>'): # a new seq
			if seqid is not None:
				if keep_anno:
					seqs.append((seqid, (anno, ''.join(seq))))
				else:
					seqs.append((seqid, ''.join(seq))) 
				del seq[:]
			seqid = line.split(' ')[0][1:]
			anno = line[len(seqid)+2:]
		elif line:
			seq.append(line)
	if keep_anno:
		seqs.append((seqid, (anno, ''.join(seq))))
	else:
		seqs.append((seqid, ''.join(seq)))
	return seqs

def readGenome(fasta, title=False, short_title=False):
	'''
	fasta: the whole genome file in FASTA format
	read the first genome - stopped by a blank row or a row starting with '>'
	return a string or a tuple: genome or (head, genome), in which the leading ">" will be removed from head
	'''
	fp = isinstance(fasta, basestring) and open(fasta) or fasta
	head = fp.readline().strip() #.replace('\n','').replace('\r','') # skip the first row: '>XXX" 
	#genome = fp.read().replace('\n','').replace('\r','')
	if head.startswith(';'): head = '' # skip annotation rows
	while not head: # skip blank rows
		head = fp.readline()
		if not head: 
			break
		head = head.strip() #.replace('\n','').replace('\r','') 
		if head.startswith(';'): head = ''
	if head.startswith('>'):
		genome, head = [], head[1:]
	else:
		genome, head = [head], ''
	for line in fp:
		line = line.strip()
		if line.startswith(';'): continue
		if not line or line.startswith('>'):
			break
		genome.append(line)
	genome = ''.join(genome)
	genome = re.sub(r'\s', '', genome)
	if title: genome = (head, genome)
	return genome

def readGenomes(fasta, title=False, short_title=False): # actually similar to readFnaSeqs !!!
	'''
	fasta: the whole genome file in FASTA format
	read all genomes
	return a list of strings or a list of tuples:  genome or (head, genome), in which the leading ">" will be removed from head
	'''
	rs = re.compile(r'[^\s]*').match # rs(s).group() return the first part
	genomes = []
	fp = isinstance(fasta, basestring) and open(fasta) or fasta
	head = fp.readline() #.strip() # skip the first row: '>XXX" 
	NOT_END = bool(head)
	head = head.strip()
	if head.startswith(';'): head = '' # skip annotation rows
	while NOT_END:
		while not head: # skip blank rows
			head = fp.readline()
			if not head:
				NOT_END = False
				break
			head = head.strip() 
			if head.startswith(';'): head = '' # skip annotation rows
		if not NOT_END: break
		if head.startswith('>'):
			genome, head = [], head[1:]
		else:
			genome, head = [head], ''
		head_next = ''
		while True:
			line = fp.readline()
			if not line:
				NOT_END = False
				break
			line = line.strip()
			if line.startswith(';'): continue
			if not line or line.startswith('>'):
				head_next = line #[1:]
				break
			genome.append(line)
		genome = ''.join(genome)
		genome = re.sub(r'\s', '', genome)
		if title: genome = (short_title and rs(head).group() or head, genome)
		genomes.append(genome)
		head = head_next
	return genomes

def complementarySeq_may_slower(s, d = {'A':'T', 'T':'A', 'G':'C', 'C':'G', 'a':'t', 't':'a', 'g':'c', 'c':'g'}):
	s = s[::-1]
	#s = s.upper()
	s = map(lambda a,d=d:d[a], s)
	return ''.join(s)

CharTable = {'uppercase':string.maketrans('ATCGatcg', 'TAGCTAGC'), 'lowercase':string.maketrans('ATCGatcg', 'tagctagc'), 'origin':string.maketrans('ATCGatcg', 'TAGCtagc')}

def complementarySeq(s, tb=CharTable['origin'], case=None):
	'''
	return complementary strand
	'''
	if not isinstance(tb, basestring): # should be a tuple: (src_str, obj_str)
		src_str, obj_str = tb
		if case == 'uppercase': obj_str = obj_str.upper()
		elif case == 'lowercase': obj_str = obj_str.lower()
		tb = string.maketrans(src_str, obj_str)
	elif case is not None:
		tb = CharTable.get(case, 'origin')
	return s[::-1].translate(tb)

TripleCodes = {
		'TTT':'F', 'TTC':'F', 'TTA':'L', 'TTG':'L', 'TCT':'S', 'TCC':'S', 'TCA':'S', 'TCG':'S', 'TAT':'Y', 'TAC':'Y', 'TAA':'X', 'TAG':'X', 'TGT':'C', 'TGC':'C', 'TGA':'X', 'TGG':'W', 
		'CTT':'L', 'CTC':'L', 'CTA':'L', 'CTG':'L', 'CCT':'P', 'CCC':'P', 'CCA':'P', 'CCG':'P', 'CAT':'H', 'CAC':'H', 'CAA':'Q', 'CAG':'Q', 'CGT':'R', 'CGC':'R', 'CGA':'R', 'CGG':'R',
		'ATT':'I', 'ATC':'I', 'ATA':'I', 'ATG':'M', 'ACT':'T', 'ACC':'T', 'ACA':'T', 'ACG':'T', 'AAT':'N', 'AAC':'N', 'AAA':'K', 'AAG':'K', 'AGT':'S', 'AGC':'S', 'AGA':'R', 'AGG':'R', 
		'GTT':'V', 'GTC':'V', 'GTA':'V', 'GTG':'V', 'GCT':'A', 'GCC':'A', 'GCA':'A', 'GCG':'A', 'GAT':'D', 'GAC':'D', 'GAA':'E', 'GAG':'E', 'GGT':'G', 'GGC':'G', 'GGA':'G', 'GGG':'G',
		'':'B', ' ':'Z'
		}
re_trans = re.compile(r'.{3}')
def translate(s, cnv=re_trans, tb=TripleCodes):
	tail = len(s) % 3
	if tail: s = s[:-tail]
	return cnv.sub(lambda a, b=tb:b.get(a.group(), 'B'), s.upper())

def getGeneIdx(colnms, col_gene=None):
	'''return the index of the column that can be used as gene ID'''
	colnms = list(colnms)
	if col_gene is not None:
		i_gene = colnms.index(col_gene)
	elif 'locus_tag' in colnms:
		i_gene = colnms.index('locus_tag')
	elif 'gene_syn' in colnms:
		i_gene = colnms.index('gene_syn')
	elif 'gene_symbol' in colnms:
		i_gene = colnms.index('gene_symbol')
	else:
		i_gene = None
	return i_gene

def findIR(colnms, genes_pos, genes_neg, strand='both', col_chr=None, col_start=None, col_end=None, col_strand=None, col_gene=None, ir_prefix='IR ', ir_join=' - ', show_strand=True):
	'''
	find Interval region between genes
	colnms, genes_pos, genes_neg: are exactly the return values from the function readGenes
	strand: can be both, positive, negative
	return value: a list of tuples - [ ( (start, end), [gene_info_cols] ), ... ]
	'''
	colnms = list(colnms)
	i_gene = getGeneIdx(colnms, col_gene=col_gene)
	if i_gene is None:
		raise NoColumnError('No gene information column "%s"!' % str(col_gene))
	if col_chr: i_chr = colnms.index(col_chr)
	if col_start: i_start = colnms.index(col_start)
	if col_end: i_end = colnms.index(col_end)
	if col_strand: i_strand = colnms.index(col_strand)
	ir_blank = [''] * len(colnms)
	ir = []
	if strand in ('both', 'negative'):
		genes = map(lambda a:((a[0][1], a[0][0]), a[1]), genes_neg.items()) # use (end, start) for negative strand
	if strand == 'both':
		genes.extend(genes_pos.items()) # add positive strand
	elif strand == 'positive':
		genes = genes_pos.items()
	if not genes: return ir
	genes.sort()
	loc_cur = 1
	gene_cur = ''
	strand_cur = ''
	#gene = None
	for loc, gene in genes:
		loc1, loc2 = loc
		if loc_cur < loc1:
			ir_new = ir_blank[:]
			ir_new[i_gene] = '%s%s%s%s' % (ir_prefix, gene_cur, ir_join, gene[i_gene])
			if col_chr:
				ir_new[i_chr] = gene[i_chr]
			if col_start:
				ir_new[i_start] = str(loc_cur)
			if col_end:
				ir_new[i_end] = str(loc1-1)
			if col_strand and show_strand:
				ir_new[i_strand] = strand_cur == gene[i_strand] and strand_cur or strand_cur+gene[i_strand]
			ir.append(((loc_cur, loc1), ir_new))
			loc_cur = loc2 + 1
			gene_cur = gene[i_gene]	
		elif loc_cur < loc2:
			loc_cur = loc2 + 1
			gene_cur = gene[i_gene]	
			if col_strand:
				strand_cur = gene[i_strand]
	ir_last = ir_blank[:]
	ir_last[i_gene] = '%s%s%s' % (ir_prefix, gene_cur, ir_join) 
	if col_chr and gene:
		ir_last[i_chr] = gene[i_chr]
	if col_start:
		ir_last[i_start] = str(loc_cur)
	if col_strand and show_strand:
		ir_new[i_strand] = strand_cur == gene[i_strand] and strand_cur or strand_cur+gene[i_strand]
	ir.append(((loc_cur, 0), ir_last)) # use 0 instead of loc_cur+loc_cur, which should be greater than the genome length
	return ir

def findLocPos_start(loc, locs, pos=True, sort_loc=False): # this version only consider loc_s!
	''' 
	Find the locations of loc in locs (only consider the start location of loc for now!), return a list of loc tuples
	loc: a segment -  (start_loc, end_loc) 
	locs: a list of segments. locs has been sorted if pos, or sorted reverse if not pos
	'''
	rlts = []
	if isinstance(loc, tuple):
		loc_s, loc_e = loc
	else: 
		loc_s = loc_e = loc
	if pos:
		for se in locs:
			if len(se) == 2:
				s, e = se
			else: # the end is not specified
				s, e = se[0], loc_s+1
			if s <= loc_s and loc_s < e:
				rlts.append(se)
			elif loc_s < s: 
				break
	else: # for negative, the start value is greater than the end value
		for se in locs:
			if len(se) == 2:
				s, e = se
			else:
				s, e =  loc_s+1, se[0]
			if s >= loc_s and loc_s > e:
				if sort_loc: 
					rlts.append(tuple(sort(list(se)))) #rlts.append((e, s))
				else:
					rlts.append(se)
			elif loc_s > s: 
				break
	return rlts

def findLocPos_badNeg_20100929(loc, locs, pos=True, sort_loc=False):
	''' 
	Find the locations of loc in locs, return a list of loc tuples
	loc: a segment -  (start_loc, end_loc) 
	locs: a list of segments. locs has been sorted if pos, or sorted reverse if not pos
	'''
	rlts = []
	if isinstance(loc, tuple) or isinstance(loc, list):
		loc_s, loc_e = min(loc), max(loc)
	else: 
		loc_s = loc_e = loc
	if pos:
		for se in locs:
			if len(se) == 2:
				s, e = se
			else: # the end is not specified
				s, e = se[0], loc_e+1
			if (s <= loc_s and loc_s < e) or (s < loc_e and loc_e <= e) or (loc_s <= s and s < loc_e) or (loc_s < e and e <= loc_e):
				rlts.append(se)
			elif loc_e <= s: 
				break
	else: # for negative, the start value is greater than the end value
		for se in locs:
			if len(se) == 2:
				s, e = se
			else:
				s, e =  loc_s+1, se[0]
			if (s >= loc_s and loc_s > e) or (s > loc_e and loc_e >= e) or (loc_s >= s and s > loc_e) or (loc_s > e and e >= loc_e):
				if sort_loc: 
					rlts.append(tuple(sorted(list(se)))) #rlts.append((e, s))
				else:
					rlts.append(se)
			elif loc_e >= s: 
				break
	return rlts

def findLocPos(loc, locs):
	''' 
	Find the locations of loc in locs, return a list of loc tuples
	loc: a segment -  (start_loc, end_loc) 
	locs: a list of segments sorted by (st, ed) -- st <= ed
	'''
	rlts = []
	if isinstance(loc, tuple) or isinstance(loc, list):
		loc_s, loc_e = min(loc), max(loc)
	else: 
		loc_s = loc_e = loc
	for se in locs:
		if len(se) == 2:
			s, e = se
		else: # the end is not specified
			s, e = se[0], loc_e+1
		if (s <= loc_s and loc_s < e) or (s < loc_e and loc_e <= e) or (loc_s <= s and s < loc_e) or (loc_s < e and e <= loc_e):
			rlts.append(se)
		elif loc_e <= s: 
			break
	return rlts

def findBestLocPos(loc, locs, pos=True, sort_loc=False): # not complete yet!!!!!
	''' 
	Find the best location of loc in locs (only consider the start location of loc for now!), return a list of loc tuples
	loc: a segment -  (start_loc, end_loc) 
	locs: a list of segments. locs has been sorted if pos, or sorted reverse if not pos
	Rules:	1. use IR XXX only when suitable STMXXX does not exist; 
			2. use STMXXX + STMXXX for probes that bridge or overlap muliptle genes.
	'''
	rlts = []
	if isinstance(loc, tuple) or isinstance(loc, list):
		loc_s, loc_e = min(loc), max(loc)
	else: 
		loc_s = loc_e = loc
	if pos:
		for se in locs:
			if len(se) == 2:
				s, e = se
			else: # the end is not specified
				s, e = se[0], loc_e+1
			if (s <= loc_s and loc_s < e) or (s < loc_e and loc_e <= e) or (loc_s <= s and s < loc_e) or (loc_s < e and e <= loc_e):
				rlts.append(se)
			elif loc_e <= s: 
				break
	else: # for negative, the start value is greater than the end value
		for se in locs:
			if len(se) == 2:
				s, e = se
			else:
				s, e =  loc_s+1, se[0]
			if (s >= loc_s and loc_s > e) or (s > loc_e and loc_e >= e) or (loc_s >= s and s > loc_e) or (loc_s > e and e >= loc_e):
				if sort_loc: 
					rlts.append(tuple(sort(list(se)))) #rlts.append((e, s))
				else:
					rlts.append(se)
			elif loc_e >= s: 
				break
	return rlts

def readGeneTab(fanno, default_chr=None, chromosome='chromosome', start='start', end='end', strand='strand', col_prefix='gene_', asc_loc=False):
	'''
	fanno:	the annotation file has columns: chromosome	start	end	strand	gene_type	gene_symbol	gene_title
	asc_loc:	force st < ed for locs (st, ed) if True. Otherwise st > ed on negative strand. 
	return a tuple: (info_col_names, info_dict)
		info_dict can be { chr:{'pos':{(start, end):[info_cols], ...},
		'neg':{(start, end):[info_cols], ...}}, ...} if strand is provided, or
		{ chr:[((start, end), [info_cols]), ...], ... } if no strand provided.
		- use list in the second situation because theoretically it is possibe
		  to have replicated (start, end) pairs (on different strands)
	'''
	fanno = TableFile(fanno) 
	head =  fanno.next()
	has_chr = chromosome in head
	has_strand = bool(strand)
	if has_strand:
		locnms = has_chr and (chromosome, start, end, strand) or (start, end, strand)
	else:
		locnms = has_chr and (chromosome, start, end) or (start, end)
	locidxs = map(head.index, locnms)
	infoidxs = range(len(head))
	#map(infoidxs.remove, locidxs) # only keep idx for other columns: gene_type, gene_symbol, gene_title
	if col_prefix:
		map(lambda a:head.__setitem__(a, col_prefix + head[a]), locidxs) # add prefix "gene_" to locnms in head
	infonms = map(head.__getitem__, infoidxs) # now infornms is same to head
	chrdic = {} # { chr:{'pos':{(start, end):[info_cols], ...}, 'neg':{(start, end):[info_cols], ...}}, ...}
	chr = default_chr
	for line in fanno:
		if has_chr: 
			if has_strand:
				chr, st, ed, strd = map(line.__getitem__, locidxs)
			else:
				chr, st, ed = map(line.__getitem__, locidxs)
		else:
			if has_strand:
				st, ed, strd = map(line.__getitem__, locidxs)
			else:
				st, ed = map(line.__getitem__, locidxs)
		#st, ed = int(st), int(ed)
		try: st = int(st)
		except: st = ''
		try: ed = int(ed)
		except: ed = ''
		infos = map(line.__getitem__, infoidxs)
		if has_strand:
			thischr = chrdic.setdefault(chr, {})
		else:
			thischr = chrdic.setdefault(chr, [])
		if has_strand:
			if strd == '+':
				loc = st <= ed and (st, ed) or (ed, st) # tuple(sorted([st, ed]))
				thistrand = thischr.setdefault('pos', {})
			else:
				if asc_loc: 
					loc =  st < ed and (st, ed) or (ed, st) 
				else:
					loc =  st > ed and (st, ed) or (ed, st) 
				thistrand = thischr.setdefault('neg', {})
			thistrand[loc] = infos
		else:
			loc = st <= ed and (st, ed) or (ed, st)
			thischr.append((loc, infos))
	return infonms, chrdic
		
def readGenes4Cols(fn = 'genome_14028S.seq', colnms=('gene', 'locus_tag', 'product', 'protein_id', 'note'), sections=['gene', 'CDS'], sep='\t'):
	'''
	Read information specified by colnms
	'''
	genes_pos, genes_neg = {}, {} # (start, end) : [gene, locus_tag, product, protein_id, note]
	cur_loc = None
	cur_dic = {}
	skip = False
	for line in open(fn):
		if line.startswith('>') or not line.strip():
			continue
		if line.startswith(sep):
			if skip or not cur_loc:
				continue
			line = line.strip()
			i = line.find(sep)
			if i >= 0:
				cur_dic[line[:i]] = line[i+1:].replace(sep, '   ')
			continue
		# line should starts with a location
		line = line.strip().split(sep)
		if sections and line[2] not in sections:
			skip = True
			continue
		else:
			skip = False
		loc = map(int, line[:2])
		if loc == cur_loc:
			continue
		elif cur_loc is None:
			cur_loc = loc
			continue
		# it is a new loc, complete the old one
		if cur_loc[0] < cur_loc[1]: # "+" strand
			genes_pos[tuple(cur_loc)] = map(lambda a:cur_dic.get(a, ''), colnms) 
		else:
			genes_neg[tuple(cur_loc)] = map(lambda a:cur_dic.get(a, ''), colnms) 
		cur_loc = loc
		cur_dic.clear()
	if cur_loc:
		if cur_loc[0] < cur_loc[1]: # "+" strand
			genes_pos[tuple(cur_loc)] = map(lambda a:cur_dic.get(a, ''), colnms) 
		else:
			genes_neg[tuple(cur_loc)] = map(lambda a:cur_dic.get(a, ''), colnms) 
	return colnms, genes_pos, genes_neg

def readGenes(fn='genome_14028S.seq', sections=['gene', 'CDS'], sep='\t'):
	fp = isinstance(fn, basestring) and open(fn) or fn
	genes_pos, genes_neg = {}, {} # (start, end) : [gene, locus_tag, product, protein_id, note]
	colnms = {}
	cur_loc = None
	loc_extra = []
	cur_dic = {}
	skip = False
	for line in fp:
		if line.startswith('>') or not line.strip():
			continue
		if line.startswith(sep): # should be a feature
			if skip or not cur_loc:
				continue
			line = line.strip()
			i = line.find(sep)
			if i >= 0:
				k = line[:i]
				cur_dic[k] = line[i+1:].replace(sep, '   ')
				if k not in colnms:
					colnms[k] = True
			else:
				cur_dic[line] = 'yes' # e.g. the feature "pseudo" has no value
				if line not in colnms:
					colnms[line] = True
			continue
		# line should starts with a location
		skip = False
		line = line.strip().split(sep)
		if sections:
			if len(line) > 2 and line[2] not in sections:
				skip = True
				continue
		if len(line) == 2: # a loc without name will be attached to the previous one, it will share information with the previous loc.
			loc_extra.append((int(line[0]), int(line[1])))
			continue
		loc = tuple(map(int, line[:2]))
		if loc == cur_loc:
			continue
		elif cur_loc is None:
			cur_loc = loc
			continue
		# it is a new loc, complete the old one
		if cur_loc[0] < cur_loc[1]: # "+" strand
			genes_pos[cur_loc] = cur_dic #map(lambda a:cur_dic.get(a, ''), colnms) 
		else:
			genes_neg[cur_loc] = cur_dic #map(lambda a:cur_dic.get(a, ''), colnms) 
		if loc_extra:
			for aloc in loc_extra:
				if aloc[0] < aloc[1]:
					genes_pos[aloc] = cur_dic
				else:
					genes_neg[aloc] = cur_dic
			del loc_extra[:]
		cur_loc = loc
		cur_dic = {} #cur_dic.clear()
	if cur_loc:
		if cur_loc[0] < cur_loc[1]: # "+" strand
			genes_pos[cur_loc] = cur_dic #map(lambda a:cur_dic.get(a, ''), colnms) 
		else:
			genes_neg[cur_loc] = cur_dic #map(lambda a:cur_dic.get(a, ''), colnms) 
	# make all rows have all columns
	colnms = colnms.keys()
	colnms.sort()
	for k, v in genes_pos.items():
		genes_pos[k] = map(lambda a:v.get(a, ''), colnms)
	for k, v in genes_neg.items():
		genes_neg[k] = map(lambda a:v.get(a, ''), colnms)
	if loc_extra:
		for aloc in loc_extra:
			if aloc[0] < aloc[1]:
				genes_pos[aloc] = cur_dic
			else:
				genes_neg[aloc] = cur_dic
	return colnms, genes_pos, genes_neg


