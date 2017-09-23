#!/usr/bin/perl

# ESearch

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my %params;
my $db = 'protein';

$params{db} = $db;
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';

#ESearch

%params = esearch(%params);

print Dumper %params;
