#!/usr/bin/perl

# ELink (by id) - EFetch

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my (%params, %links);
my @db = qw(gene protein,pubmed);
my $name;

#ELink
$params{db} = $db[0];
$params{id} = '192305,11566,159,522529';

%links = elink_by_id_to($db[1], %params);

#EFetch

foreach $name (keys %links) {

  %params = extract_links($name, %links);

  $params{outfile} = $name . '.dat';
  $params{retmode} = 'text';

  if ($name =~ /protein/) {
    $params{rettype} = 'fasta';
  }
  elsif ($name =~ /pubmed/) {
    $params{rettype} = 'abstract';
  }    

  efetch_batch(%params);

}
