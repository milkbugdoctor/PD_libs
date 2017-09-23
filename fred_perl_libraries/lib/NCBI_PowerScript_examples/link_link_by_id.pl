#!/usr/bin/perl

# ELink (batch) - ELink (by id)

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(gene protein cdd,nucleotide);
my @uids;
my $name;

#ELink 1

$params{db} = $db[0];
$params{id} = '22949,10800,57105,56413';

%links = elink_batch_to($db[1], %params);

#ELink 2

%params = extract_links('gene_protein', %links);

%links = elink_by_id_to($db[2], %params);

