#!/usr/bin/perl

# EPost

use strict;
use NCBI_PowerScripting;
use Data::Dumper;

my %params;
my $db = 'protein';

#EPost
$params{db} = $db;
$params{id} = 'proteins.gi';

%params = epost_file(%params);

print Dumper %params;


