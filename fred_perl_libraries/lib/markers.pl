#!/usr/bin/perl

#
#	Use "hash" Box option for sparse sets.
#

use Boxes;
require 'misc.pl';

package markers;

# use Time::HiRes qw(time alarm sleep);
use Carp;

#   markers::new(@options)
#
#   default options: (700, nohash)
#
#   Options:
#	hash     : hash box entries
#	nohash   : don't hash box entries
#	use_refs : store markers as array refs instead of strings
#
sub new {
    shift if $_[0] eq 'markers';
    my (@options) = @_;
    my $self = {};
    bless $self;
    $self->{'marker_array'} = [ ];
    $self->{'marker_hash'} = { };
    if (grep($_ eq 'use_refs', @options)) {
	$self->{use_refs} = 1;
	@options = grep($_ ne 'use_refs', @options);
    } 
    $self->{'box_options'} = [ 700, 'nohash', @options ];
    return $self;
}


#
#   too many options: use_refs, wantarray, with_index
#
sub get_marker {
    my ($self, $index, $with_index) = @_;
    my $array = $self->{'marker_array'};
    if (wantarray) {
	my @array;
	if ($self->{use_refs}) {
	    @array = @{$array->[$index]};
	}
	else {
	    @array = split(/\t/, $array->[$index])
	}
	push(@array, $index) if $with_index;
	return @array;
    }
    # does not want array
    return $array->[$index] if ! $with_index;
    if ($self->{use_refs}) {	# use_refs + with_index
	return [ @{$array->[$index]}, $index ];	# unwrap and rewrap
    }
    else {
	return $array->[$index] . "\t" . $index;
    }
}


sub get_marker_array_ref {
    my ($self) = @_;
    return $self->{'marker_array'};
}


##############################################################################
#
#   $cover:
#	any        - any amount of overlap
#	all        - all of input sequence is covered by a marker
#	all_me     - same as 'all'
#	all_marker - all of marker is covered by input sequence
#	<number>   - at least this many bases
#
#   Returns array of marker fields:
#       $chr $strand $start $end @rest
#   The fields will be tab-delimited unless 'use_refs' is used.
#
##############################################################################
sub get_covering_markers {
    my ($self, $cover, $chr, $strand, $start, $end, $with_index) = @_;
    my @indexes = get_covering_marker_indexes(@_);
    my @markers;
    for my $i (@indexes) {
	push(@markers, scalar get_marker($self, $i, $with_index));
    }
    return @markers;
}


##############################################################################
#
#   $cover:
#	any        - any amount of overlap
#	all        - all of input sequence is covered by a marker
#	all_me     - same as 'all'
#	all_marker - all of marker is covered by input sequence
#	<number>   - at least this many bases
#
#   And you can combine them:  3|all_marker
#
#   Returns array of marker indexes.
#
##############################################################################
sub get_covering_marker_indexes {
    my ($self, $cover, $chr, $strand, $start, $end) = @_;
    my $hash = $self->{'marker_hash'};
    my $array = $self->{'marker_array'};
    my $boxes = $hash->{$strand}{$chr};
    return () if !defined($boxes);
    my ($first, $last) = $boxes->box_num($start, $end);
    my %markers;
    for my $i ($first .. $last) {
	my $box = $boxes->box_ref($i);
	next if !defined($box);
	for my $index (@$box) {
	    next if $markers{$index};
	    my ($s, $e) = (get_marker($self, $index))[2, 3];
	    my $left = ::max($start, $s);
	    my $right = ::min($end, $e);
	    for my $cov (split /\|/, $cover) {
		if ($cov eq 'any') {
		    $markers{$index} = $index if $left <= $right;
		}
		elsif ($cov eq 'all_marker') {
		    $markers{$index} = $index if $start <= $s and $end >= $e;
		}
		elsif ($cov =~ /^(all|all_me)$/) {
		    $markers{$index} = $index if $s <= $start and $e >= $end;
		}
		elsif ($cov > 0) {
		    $markers{$index} = $index if $right - $left + 1 >= $cov;
		}
		else {
		    confess "unknown cover type '$cover' subtype '$cov'";
		}
	    }
	}
    }
    return keys %markers;
}


#   add_marker($chr, $strand, $start, $end, @rest);
#
#   Sets:
#	@marker_array
#	$marker_start{strand}{chr} - array references
#   Returns:
#	marker index
#
sub add_marker {
    my $self = shift;
    my ($chr, $strand, $start, $end, @rest) = @_;
    confess "start > end" if $start > $end;
    my $hash = $self->{'marker_hash'};
    my $array = $self->{'marker_array'};
    my $index = scalar @$array;
    if ($self->{use_refs}) {
	push(@$array, [ @_ ]);
    }
    else {
	push(@$array, join("\t", @_));
    }
    my $boxes = $hash->{$strand}{$chr};
    if (!defined($boxes)) {
	$boxes = Boxes::new(@{$self->{'box_options'}});
	$hash->{$strand}{$chr} = $boxes;
    }
    my ($first, $last) = $boxes->box_num($start, $end);
    $boxes->add_range($first, $last, $index);
    return $index;
}


#
#   $markers->delete_marker(index)
#
sub delete_marker {
    my $self = shift;
    my ($index) = @_;
    my $hash = $self->{'marker_hash'};
    my $array = $self->{'marker_array'};
    my ($chr, $strand, $start, $end) = get_marker($self, $index);
    $array->[$index] = undef;
    my $boxes = $hash->{$strand}{$chr};
    if (!defined($boxes)) {
	confess "huh? can't find any boxes!";
    }
    my ($first, $last) = $boxes->box_num($start, $end);
    $boxes->delete_range($first, $last, $index);
    return $index;
}

sub get_nearest_markers {
    my @indexes = get_nearest_marker_indexes(@_);
    my @markers;
    my $self = $_[0];
    for my $i (@indexes) {
	push(@markers, [ get_marker($self, $i) ]);
    }
    return @markers;
}

#
#   $dir == 1  means to the right
#   $dir == -1 means to the left
#
sub get_nearest_marker_indexes {
    my ($self, $chr, $strand, $start, $end, $dir) = @_;
    my $hash = $self->{'marker_hash'};
    my $array = $self->{'marker_array'};
    my $boxes = $hash->{$strand}{$chr};
    return () if !defined($boxes);
    my ($first, $last) = $boxes->box_num($start, $end);
    my %markers;
    my $best_dist = -1;
    if ($dir == -1) {
	for (my $i = $last; $i >= 0; $i--) {
	    my $box = $boxes->box_ref($i);
	    next if !defined($box);
	    for my $index (@$box) {
		next if $markers{$index};
		my ($s, $e) = (get_marker($self, $index))[2, 3];
		my $left = ::max($start, $s);
		my $right = ::min($end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = $start - $e;
		}
		next if $dist < 0;
		if ($best_dist < 0 || $dist < $best_dist) {
		    %markers = ();
		    $markers{$index} = 1;
		    $best_dist = $dist;
		}
		elsif ($dist == $best_dist) {
		    $markers{$index};
		}
	    }
	    last if ($i <= $first && %markers > 0);
	}
    }
    elsif ($dir == 1) {
	my $last_box = $boxes->last_box();
	for (my $i = $first; $i <= $last_box; $i++) {
	    my $box = $boxes->box_ref($i);
	    next if !defined($box);
	    for my $index (@$box) {
		next if $markers{$index};
		my ($s, $e) = (get_marker($self, $index))[2, 3];
		my $left = ::max($start, $s);
		my $right = ::min($end, $e);
		my $dist;
		if ($left <= $right) {
		    $dist = 0;
		}
		else {
		    $dist = $s - $end;
		}
		next if $dist < 0;
		if ($best_dist < 0 || $dist < $best_dist) {
		    %markers = ();
		    $markers{$index} = 1;
		    $best_dist = $dist;
		}
		elsif ($dist == $best_dist) {
		    $markers{$index};
		}
	    }
	    last if ($i >= $last && %markers > 0);
	}
    }
    else {
	die "\$dir must be -1 or 1";
    }
    return keys %markers;
}

1;
