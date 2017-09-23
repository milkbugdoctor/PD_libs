#!/usr/bin/perl

# EPost - ESearch

use strict;
use NCBI_PowerScripting;

my %params;
my $db = 'protein';
my @uids;

#EPost
$params{db} = $db;
$params{id} = 'prot_gi.in';

%params = epost_file(%params);

#ESearch

$params{term} = "%23$params{'query_key'}+AND+2007[mdat]";
$params{usehistory} = 'y';

%params = esearch(%params);

#Retreive UIDs

@uids = get_uids(%params);

foreach (@uids) { print "$_ "; }
print "\n";
