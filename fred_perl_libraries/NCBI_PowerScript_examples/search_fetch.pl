#!/usr/bin/perl

# ESearch - EFetch

use strict;
use NCBI_PowerScripting;

my %params;
my $db = 'protein';

#ESearch
$params{db} = $db;
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';

%params = esearch(%params);

#EFetch

$params{rettype} = 'fasta';
$params{retmode} = 'text';
$params{outfile} = 'fasta.out';

efetch_batch(%params);
