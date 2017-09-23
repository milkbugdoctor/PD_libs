#!/usr/bin/perl

# ELink (batch) - ESummary

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(protein gene);
my $name;

#ELink

$params{db} = $db[0];
$params{id} = '56181376,56181374,56181372,15718680';

%links = elink_batch_to($db[1], %params);

#ESummary

foreach $name (keys %links) {

  %params = extract_links($name, %links);
  $params{outfile} = $name . '.sum';

  esummary(%params);

}
