#!/usr/bin/perl

# ELink (batch) - EFetch

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(gene protein,pubmed);
my $link;

#ELink

$params{db} = $db[0];
$params{id} = '22949,10800,57105,56413';

%links = elink_batch_to($db[1], %params);

#EFetch

foreach $link (keys %links) {

  %params = extract_links($link, %links);
  $params{outfile} = $link . '.dat';
  $params{retmode} = 'text';

  if ($link =~ /protein/) {
    $params{rettype} = 'fasta';
  }
  elsif ($link =~ /pubmed/) {
    $params{rettype} = 'abstract';
  }    

  efetch_batch(%params);

}
