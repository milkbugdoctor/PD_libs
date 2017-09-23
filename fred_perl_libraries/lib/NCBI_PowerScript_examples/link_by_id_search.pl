#!/usr/bin/perl

# ELink (by id) - ESearch

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my (%params, %links);
my @db = qw(gene protein,pubmed);
my $link = 'gene_protein';

#ELink

$params{db} = $db[0];
$params{id} = '6580,23057,3236';

%links = elink_by_id_to($db[1], %params);

#ESearch for each id

%params = extract_links($link, %links);
$params{term} = "srcdb+refseq[prop]+AND+#";

%params = esearch_links(%params);
