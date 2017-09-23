#!/usr/bin/perl

#
#   FIX: could be faster if we used binary search
#

require "misc.pl";	# max()

package NearestMarker;

sub new {
    my $hash = { };
    bless $hash;
}

#
#   ($dist, $entry) = $near->get_nearest_marker(contig, start, end, direction)
#
#   direction: -1 or 1
#
#   $entry = [ $start, $end, @rest ]
#
sub get_nearest_marker {
    my $hash = shift;
    my ($contig, $marker_start, $marker_end, $direction) = @_;
    $hash->sort_markers() if ! $hash->{sorted};
    my $start = $hash->{starts}{$contig};
    my $end   = $hash->{ends}{$contig};
    my $array = $hash->{markers}{$contig};
    if ($direction < 0) {
	for (my $i = $#{$start}; $i >= 0; $i--) {
	    my ($s, $index) = split(/ /, ${$start}[$i]);
	    if ($s <= $marker_end) {
		my $e = $array->[$index][1];
		my $left = ::max($marker_start, $s);
		my $right = ::min($marker_end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = ($marker_start - $e);
		}
		return ($dist, [ @{$array->[$index]} ]);
	    }
	}
    }
    else {
	for (my $i = 0; $i <= $#{$end}; $i++) {
	    my ($e, $index) = split(/ /, ${$end}[$i]);
	    if ($e >= $marker_start) {
		my $s = $array->[$index][0];
		my $left = ::max($marker_start, $s);
		my $right = ::min($marker_end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = ($s - $marker_end);
		}
		return ($dist, [ @{$array->[$index]} ]);
	    }
	}
    }
    return undef;
}

#
#   Nearest::add_marker($contig_id, $start, $end, @rest)
#
#   E.g.:
#       $nearest->add_marker("chrY", $start, $end, @other_stuff);
#       $nearest->add_marker("chr2/+", $start, $end, @other_stuff);
#
sub add_marker {
    my $hash = shift;
    my ($contig, $start, $end, @rest) = @_;
    $hash->{contigs}{$contig} = 1;
    push(@{$hash->{markers}{$contig}}, [$start, $end, @rest]);
    my $index = $#{$hash->{markers}{$contig}};
    push(@{$hash->{starts}{$contig}}, "$start $index");
    push(@{$hash->{ends}{$contig}}, "$end $index");
}

sub sort_markers {
    my $hash = shift;
    @contig = keys %{$hash->{contigs}};
    for my $contig (@contig) {
	@{$hash->{starts}{$contig}} = sort { $a <=> $b } @{$hash->{starts}{$contig}};
	@{$hash->{ends}{$contig}}   = sort { $a <=> $b } @{$hash->{ends}{$contig}};
    }
    $hash->{sorted} = 1;
}

1;
