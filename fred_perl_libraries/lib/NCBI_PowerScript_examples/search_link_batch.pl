#!/usr/bin/perl

# ESearch - ELink (batch)
# UIDs are recovered with get_uids

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my (%params, %links);
my @db = qw(protein gene,pubmed,nuccore);
my @uids;
my $name;

#ESearch
$params{db} = $db[0];
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';

%params = esearch(%params);

#ELink

%links = elink_batch_to($db[1], %params);
print Dumper %links;
#Recover UIDs for each linkname

get_link_report(%links);
