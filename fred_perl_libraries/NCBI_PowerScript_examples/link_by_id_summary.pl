#!/usr/bin/perl

# ELink (by id) - ESummary

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(gene protein,pubmed);
my $name;

#ELink
$params{db} = $db[0];
$params{id} = '22949,10800,57105,56413';
$params{outfile} = 'links';

%links = elink_by_id_to($db[1], %params);

#ESummary

foreach $name (keys %links) {

  %params = extract_links($name, %links);
  $params{outfile} = $name . '.sum';

  esummary(%params);

}
