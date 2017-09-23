#!/usr/bin/perl

# ESearch - ELink (by id)
# UIDs are written to an index file 'links.idx'

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my (%params, %links);
my @db = qw(nuccore gene,pubmed,nuccore);

#ESearch
$params{db} = $db[0];
$params{term} = 'mouse[orgn]+AND+transcarbamylase[title]';

%params = esearch(%params);

#ELink

$params{outfile} = 'links';

%links = elink_by_id_to($db[1], %params);

get_link_report(%links);

print Dumper %links;

