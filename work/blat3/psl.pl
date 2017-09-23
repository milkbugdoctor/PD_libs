#!/usr/local/bin/perl

use Columns;
require 'sequences.pl';

sub psl_to_hits {
    my ($cols, $row) = @_;
    my ($qname, $tstarts, $blocksizes, $tname)
	= $cols->get_col($row, 'qname', 'tstarts', 'blocksizes', 'tname');
    my @tstarts = split /,/, $tstarts;
    my @blocks = split /,/, $blocksizes;
    my @hits;
    for my $i (0 .. $#blocks) {
	my $start = $tstarts[$i] + 1;
	my $end = $tstarts[$i] + $blocks[$i];
	my $len = $blocks[$i];
	push(@hits, join("\t", $qname, $start, $end, $len, $tname));
    }
    return @hits;
}

1;
