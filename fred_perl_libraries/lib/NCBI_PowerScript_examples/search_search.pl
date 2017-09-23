#!/usr/bin/perl

# ESearch - ESearch
# This example limits the results of the first search with the query in $term2

use strict;
use NCBI_PowerScripting;

my %params;
my @final;
my $db = 'protein';
my $term2 = '+AND+srcdb+refseq[prop]';

#ESearch 1
$params{db} = $db;
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';
$params{usehistory} = 'y';

%params = esearch(%params);

print "The first search returned $params{count} records.\n";

#ESearch 2

$params{term} = "%23$params{query_key}" . $term2;

%params = esearch(%params);

@final = get_uids(%params);

print "The second search returned $params{count} records:\n";
foreach (@final) { print "$_ "; }
print "\n";
