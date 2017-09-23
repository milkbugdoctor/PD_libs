#!/usr/bin/perl

# EPost - EFetch

use strict;
use NCBI_PowerScripting;

my %params;
my $db = 'protein';

#EPost
$params{db} = $db;
$params{id} = 'prot_gi.in';

%params = epost_file(%params);

#EFetch

$params{rettype} = 'fasta';
$params{retmode} = 'text';
$params{outfile} = 'posted.dat';

efetch_batch(%params);


