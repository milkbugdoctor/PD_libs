#!/usr/bin/perl

# ESearch - ESummary

use strict;
use NCBI_PowerScripting;

my %params;
my $db = 'protein';

$params{db} = $db;
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';

#ESearch

%params = esearch(%params);

#ESummary

$params{outfile} = 'docsums.out';

esummary(%params);
