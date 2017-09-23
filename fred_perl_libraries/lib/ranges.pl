#!/usr/bin/perl

require 'misc.pl';

use Carp 'confess';

#
# $range = [ start, end, ... ]
#
sub range_add {
    my ($start, $end, $range, $quick) = @_;
    if ($quick) {
	push(@$range, $start, $end);
	return;
    }
    my @range = @$range;
    my @result;
    for (my $i = 0; $i < $#range; $i += 2) {
	my ($rstart, $rend) = @range[$i, $i + 1];
	if (!range_pair_overlap($start - 1, $end + 1, $rstart, $rend)) {
	    push(@result, $rstart, $rend);
	    next;
	}
	splice(@range, $i, 2);
	$start = min($start, $rstart);
	$end = max($end, $rend);
	$i -= 2;
    }
    push(@result, $start, $end);
    @result = sort { $a <=> $b } @result;
    @$range = @result;
    $_[2] = $range;	# in case $range was undefined
}

sub range_sub {
    my ($start, $end, $range) = @_;
    my @range = @$range;
    for (my $i = 0; $i < $#range; $i += 2) {
	my ($rstart, $rend) = @range[$i, $i + 1];
	next if ! range_pair_overlap($start, $end, $rstart, $rend);
	splice(@range, $i, 2);
	splice(@range, $i, 0, $end + 1, $rend) if $end < $rend;
	splice(@range, $i, 0, $rstart, $start  - 1) if $start > $rstart;
	$i -= 2;
    }
    @$range = @range;
    $_[2] = $range;	# in case $range was undefined
}

#
#   Subtract second from first range, returning new range.
#
sub range_subtract {
    my ($first, $second) = @_;
    my $range = [ ];
    @$range = @$first;
    for (my $i = 0; $i < $#{$second}; $i += 2) {
	my ($rstart, $rend) = @{$second}[$i, $i + 1];
	range_sub($rstart, $rend, $range);
    }
    return $range;
}

#
#   $range = range_intersect($range1, $range2)
#
#   Return subranges that intersect; does not merge results.
#
sub range_intersect {
    my ($range1, $range2) = @_;
    my @range1 = @$range1;
    my @range2 = @$range2;
    my $result;
    for (my $i = 0; $i < $#range1; $i += 2) {
	my @sub1 = @range1[$i, $i + 1];
	for (my $j = 0; $j < $#range2; $j += 2) {
	    my @sub2 = @range2[$j, $j + 1];
	    my @pair = range_pair_overlap(@sub1, @sub2);
	    push(@$result, @pair) if @pair == 2;
	}
    }
    return $result;
}

#
#   Does this segment overlap the range?
#
sub range_overlap {
    my ($start, $end, $range) = @_;
    my @range = @$range;
    for (my $i = 0; $i < $#range; $i += 2) {
	my ($rstart, $rend) = @range[$i, $i + 1];
	my @pair = range_pair_overlap($start, $end, $rstart, $rend);
	return @pair if @pair == 2;
    }
    return undef;
}

sub range_pair_overlap {
    my ($s1, $e1, $s2, $e2) = @_;
    my $left = max($s1, $s2);
    my $right = min($e1, $e2);
    return ($left, $right) if ($left <= $right);
    return undef;
}

#
#   range_merge(max_gap, ranges)
#
#	gap is (start - end - 1)
#
sub range_merge {
    my ($gap, $range) = @_;

    my @range = @$range;
    my @contigs;

    for (my $i = 0; $i < $#range; $i += 2) {
	if ($range[$i] > $range[$i+1] or $range[$i] eq '' or $range[$i+1] eq '') {
	    confess "bad range ($range[$i], $range[$i+1])";
	}
	push(@contigs, "$range[$i] $range[$i+1]");
    }

    while (1) {
	my $did_something = 0;
	@contigs = sort {
	    my ($a_start, $a_end) = split /\s+/, $a;
	    my ($b_start, $b_end) = split /\s+/, $b;
	    return $a_start <=> $b_start or $a_end <=> $b_end;
	} @contigs;
	for (my $i = 0; $i < $#contigs; $i++) {
	    my ($a_start, $a_end) = split /\s+/, $contigs[$i];
	    my ($b_start, $b_end) = split /\s+/, $contigs[$i + 1];
	    my $s = max($a_start, $b_start);
	    my $e = min($a_end, $b_end);
	    if ($s - $e - 1 <= $gap) {
		my $s = min($a_start, $b_start);
		my $e = max($a_end, $b_end);
		$contigs[$i] = "$s $e";		# merge 
		splice(@contigs, $i + 1, 1);	# remove 2nd
		$did_something = 1;
		$i--;
		next;
	    }
	}
	# move this below loop
	@range = ();
	for (my $i = 0; $i <= $#contigs; $i++) {
	    my ($start, $end) = split /\s+/, $contigs[$i];
	    push(@range, $start, $end);
	}
	last if ! $did_something;
    }
    @$range = @range;
}


#
#   range4_merge(\@range)
#
#	Each element is a subrange: [start, end, left_overlap, right_overlap]
#
#	Merges as much as possible without losing valuable information that would
#	keep us from adding more reads later.
#
sub range4_merge {
    my ($range) = @_;
    for my $s (@$range) {
	if ($s->[0] > $s->[1] or $s->[0] eq '' or $s->[1] eq '') {
	    confess "bad range ($s->[0], $s->[1]) from $s: [@$s]";
	}
    }
    # the principle is that when we loose an end by extension, we want to keep the
    # overlap penalty from increasing
    @$range = sort {
	$a->[0] <=> $b->[0];
    } @$range;
    while (1) {
	my $did_something = 0;
	for (my $i = 0; $i < $#{$range}; $i++) {
	    my $a = $range->[$i];
	    my ($as, $ae, $al, $ar) = @$a;
	    for (my $j = $i + 1; $j <= $#{$range}; $j++) {
		my $b = $range->[$j];
		my ($bs, $be, $bl, $br) = @$b;
		die "huh?" if $bs < $as;
		last if $bs > $ae;
		if ($as <= $bs and $be <= $ae and $al <= $bl and $ar <= $br) {	# a subsumes b
		    splice(@$range, $j, 1);	# remove 2nd range
		    $did_something = 1;
		    $j--;
		    next;
		}
		if ($bs <= $as and $ae <= $be and $bl <= $al and $br <= $ar) {	# b subsumes a
		    # $bs == $as at this point so it's ok to change @$a without resorting
		    @$a = ($bs, $be, $bl, $br);
		    ($as, $ae, $al, $ar) = @$a;
		    splice(@$range, $j, 1);	# remove 2nd range
		    $did_something = 1;
		    $j--;
		    next;
		}
		my $s = max($as, $bs);
		my $e = min($ae, $be);
		my $ov = $e - $s + 1;
		#
		# see if we can replace $bs/$bl with $as/$al and $ae/$ar with $be/$br
		#
		if ($ae <= $be and $ov >= $ar and $ov >= $bl and $al <= $bl and $br <= $ar) {
		    $ae = $be; $ar = $br;
		    @$a = ($as, $ae, $al, $ar);
		    splice(@$range, $j, 1);	# remove 2nd range
		    $did_something = 1;
		    $j--;
		    next;
		}
	    }
	}
	last if ! $did_something;
    }
}


#
#   range_simplify(ranges) - remove redundant (enclosed) ranges
#
sub range_simplify {
    my ($range) = @_;
    return if @$range == 0;
    my @range = @$range;
    my @contigs;

    for (my $i = 0; $i < $#range; $i += 2) {
	if ($range[$i] > $range[$i+1] or $range[$i] eq '' or $range[$i+1] eq '') {
	    confess "bad range ($range[$i], $range[$i+1])";
	}
	push(@contigs, "$range[$i] $range[$i+1]");
    }

    while (1) {
	my $did_something = 0;
	@contigs = sort {
	    my ($a_start, $a_end) = split /\s+/, $a;
	    my ($b_start, $b_end) = split /\s+/, $b;
	    return $a_start <=> $b_start || $b_end <=> $a_end;
	} @contigs;
	for (my $i = 0; $i < $#contigs; $i++) {
	    my ($a_start, $a_end) = split /\s+/, $contigs[$i];
	    for (my $j = $i + 1; $j <= $#contigs; $j++) {
		my ($b_start, $b_end) = split /\s+/, $contigs[$j];
		last if $b_start > $a_end;
		if ($a_start <= $b_start and $b_end <= $a_end) {
		    splice(@contigs, $j, 1);	# remove 2nd
		    $did_something = 1;
		    $j--;
		}
	    }
	}
	last if ! $did_something;
    }
    @range = ();
    for (my $i = 0; $i <= $#contigs; $i++) {
	my ($start, $end) = split /\s+/, $contigs[$i];
	push(@range, $start, $end);
    }
    @$range = @range;
}

#
#   How many bases does this range cover?
#
sub range_sum {
    my ($range) = @_;
    my $sum;
    for (my $i = 0; $i < $#range; $i += 2) {
	my ($rstart, $rend) = @range[$i, $i + 1];
	$sum += $rend - $rstart + 1;
    }
    return $sum;
}

#
#   range4_simplify(ranges) - remove redundant (enclosed) ranges
#
sub range4_simplify {
    my ($range) = @_;
    return if @$range == 0;
    while (1) {
	my $did_something = 0;
	@$range = sort {
	    return $a->[0] <=> $b->[0] || $b->[1] <=> $a->[1];
	} @$range;
	for (my $i = 0; $i < $#{$range}; $i++) {
	    my ($a_start, $a_end) = @{$range->[$i]};
	    for (my $j = $i + 1; $j <= $#{$range}; $j++) {
		my ($b_start, $b_end) = @{$range->[$j]};
		last if $b_start > $a_end;
		if ($a_start <= $b_start and $b_end <= $a_end) {
		    splice(@$range, $j, 1);	# remove 2nd
		    $did_something = 1;
		    $j--;
		}
	    }
	}
	last if ! $did_something;
    }
}

sub range4_to_range2 {
    my ($range) = @_;
    my @range2;
    for (my $i = 0; $i <= $#{$range}; $i++) {
	my ($start, $end) = @{$range->[$i]};
	push(@range2, $start, $end);
    }
    return \@range2;
}

my $test = 0;

if ($test) {
    my $range = [];
    while (1) {
	printf STDERR "/[+-] start end/ or /merge \d+/: ";
	$_ = <>;
	last if ! $_;
	chomp;
	if (/merge (\d+)/) {
	    range_merge($1, $range);
	}
	elsif (/([-+])?\s*([\d.]+)\s+([\d.]+)/) {
	    warn "got $1 $2 $3\n";
	    if ($1 eq '-') {
		range_sub($2, $3, $range, 1);
	    }
	    else {
		range_add($2, $3, $range, 1);
	    }
	}
	warn "range: @$range\n";
    }
    print "\n";
}

1;
