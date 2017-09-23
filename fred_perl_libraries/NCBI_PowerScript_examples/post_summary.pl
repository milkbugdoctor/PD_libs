#!/usr/bin/perl

# EPost - ESummary

use strict;
use NCBI_PowerScripting;

my %params;
my $db = 'protein';

#EPost
$params{db} = $db;
$params{id} = 'prot_gi.in';

%params = epost_file(%params);
#ESummary

$params{outfile} = 'posted.sum';

esummary(%params);


