#!/usr/bin/perl

use strict;
use LWP::Simple;

my $base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
my ($url, $raw);

$url = $base . "esearch.fcgi?db=protein&term=mouse[orgn]+AND+transcarbamylase[title]&usehistory=y";

$raw = get($url);

print $raw;
