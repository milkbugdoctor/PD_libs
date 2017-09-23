#!/usr/bin/perl

# EPost - ELink (batch)
# UIDs are recovered with get_uids

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(protein gene,pubmed);
my @uids;
my $name;

#EPost
$params{db} = $db[0];
$params{id} = 'prot_gi.in';

%params = epost_file(%params);

#ELink

%links = elink_batch_to($db[1], %params);

get_link_report(%links);
