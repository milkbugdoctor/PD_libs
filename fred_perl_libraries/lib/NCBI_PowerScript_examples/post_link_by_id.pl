#!/usr/bin/perl

# EPost - ELink (by id)
# UIDs are written to an index file 'links.idx'

use strict;
use NCBI_PowerScripting;

my (%params, %links);
my @db = qw(protein gene,pubmed);

#EPost
$params{db} = $db[0];
$params{id} = 'prot_gi.in';

%params = epost_file(%params);

#ELink

$params{outfile} = 'links';

%links = elink_by_id_to($db[1], %params);
