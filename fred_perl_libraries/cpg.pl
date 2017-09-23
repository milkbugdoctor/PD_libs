#!/usr/bin/perl

#
#	goldenpath start positions are 0-based, but ends are 1-based
#

my $default_db = "gp_hg18";
my $table = "cpgIslandExt";

require 'mysql.pl';
require 'misc.pl';

sub get_nearest_CpG {
    my ($chrom, $marker_start, $marker_end, $direction) = @_;
    my $start = $CpG_start{$chrom};
    my $end = $CpG_end{$chrom};
    if ($direction < 0) {
	for (my $i = $#{$start}; $i >= 0; $i--) {
	    my ($s, $index) = split(/ /, ${$start}[$i]);
	    if ($s <= $marker_end) {
		my ($e) = (split(/\t/, $CpG_array[$index]))[2];
		my $left = max($marker_start, $s);
		my $right = min($marker_end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = ($marker_start - $e);
		}
		return ($s, $e, $dist);
	    }
	}
    }
    else {
	for (my $i = 0; $i <= $#{$end}; $i++) {
	    my ($e, $index) = split(/ /, ${$end}[$i]);
	    if ($e >= $marker_start) {
		my ($s) = (split(/\t/, $CpG_array[$index]))[1];
		my $left = max($marker_start, $s);
		my $right = min($marker_end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = ($s - $marker_end);
		}
		return ($s, $e, $dist);
	    }
	}
    }
    return ('', '', '');
}

sub get_nearest_CpG_2 {
    my ($chrom, $pos, $direction) = @_;
    my $start = $CpG_start{$chrom};
    my $end = $CpG_end{$chrom};
    if ($direction < 0) {
	for (my $i = $#{$start}; $i >= 0; $i--) {
	    my ($s, $index) = split(/ /, ${$start}[$i]);
	    if ($s <= $pos) {
		return (split(/\t/, $CpG_array[$index]))[1, 2, 4, 5, 6];
	    }
	}
    }
    else {
	for (my $i = 0; $i <= $#{$end}; $i++) {
	    my ($e, $index) = split(/ /, ${$end}[$i]);
	    if ($e >= $pos) {
		return (split(/\t/, $CpG_array[$index]))[1, 2, 4, 5, 6];
	    }
	}
    }
print "got blanks on $chrom at $pos\n";
    return ('\N', '\N', '\N', '\N', '\N');
}


#
#   Sets
#	@CpG_array
#	%CpG_start{chr} and %CpG_end{chr}, which hold array references
#
sub get_CpG_info {
    my ($db) = @_;
    $db = $default_db if $db eq '';
    @CpG_array = mysql_chomp_noheader("select chrom, chromStart+1, chromEnd,
	    name, length, cpgNum, gcNum, perCpg, perGc from $db.$table");
    my (%chr, @chr);
    for (my $i = 0; $i <= $#CpG_array; $i++) {
	my ($chr, $start, $end) = split(/\t/, $CpG_array[$i]);
	$chr{$chr} = 1;
	push(@{$CpG_start{$chr}}, "$start $i");	# put pos 1st for easy sorting
	push(@{$CpG_end{$chr}}, "$end $i");
    }
    @chr = keys %chr;
    for my $chr (@chr) {
	@{$CpG_start{$chr}} = sort { $a <=> $b } @{$CpG_start{$chr}};
	@{$CpG_end{$chr}} = sort { $a <=> $b } @{$CpG_end{$chr}};
    }
}

1;
