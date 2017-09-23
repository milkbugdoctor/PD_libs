#!/usr/bin/perl

# ELink (batch) - ESearch

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(gene protein,pubmed);
my @uids;

#ELink

$params{db} = $db[0];
$params{id} = '22949,10800,57105,56413';

%links = elink_batch_to($db[1], %params);

#ESearch

%params = extract_links('gene_protein', %links);
$params{term} = "%23$params{'query_key'}+AND+srcdb+refseq[prop]";

%params = esearch(%params);

#Recover UIDs

@uids = get_uids(%params);

foreach (@uids) { print "$_ ";}
print "\n";
