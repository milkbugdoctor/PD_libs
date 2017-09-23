#!/usr/bin/perl

#
#   Each Box is an array of items.  Each Boxes class contains either a
#   Box array or a Box hash.  You should use a hash for sparse sets.
#

package Boxes;

sub new {
    my (@options) = @_;
    @options = split /\s+/, "@options";
    my $self = {};
    bless $self;
    $self->{'box_size'} = 500;
    $self->{'use_hash'} = 1;
    for my $opt (@options) {
	if ($opt > 0) {
	    $self->{'box_size'} = $opt;
	}
	if ($opt eq "hash") {
	    $self->{'use_hash'} = 1;
	}
	if ($opt eq "nohash") {
	    $self->{'use_hash'} = 0;
	}
    }
    return $self;
}

sub set_box_size {
    my $self = shift;
    my ($val) = @_;
    $self->{'box_size'} = $val;
}

#
#   Return the box number (index) for the position
#
sub box_num {
    my $self = shift;
    my @result;
    for my $box (@_) {
	push(@result, int($box / $self->{'box_size'}));
    }
    return @result if wantarray;
    return $result[0];
}

#
#   Return array references for all boxes specified by the indexes
#
sub box_ref {
    my $self = shift;
    my @result;
    my $container = $self->{'container'};
    my $use_hash = $self->{'use_hash'};
    for my $box (@_) {
	push(@result, $use_hash ?
	    [ keys %{$container->{$box}} ] : [ keys %{$container->[$box]} ]
	);
    }
    return @result if wantarray;
    return $result[0];
}

sub box_item {
    my $self = shift;
    my ($box_num, $item_num) = @_;
    my $box_ref = box_ref($self, $box_num);
    return $box_ref->[$item_num];
}

sub last_box {
    my ($self) = @_;
    return $self->{'last_box'};
}

sub delete_value {
    my ($self, $val, @boxes) = @_;
    my $use_hash = $self->{'use_hash'};
    for my $num (@boxes) {
	if ($use_hash) {
	    delete $self->{'container'}->{$num}->{$val};
	}
	else {
	    delete $self->{'container'}->[$num]->{$val};
	}
	$self->{'last_box'} = $num if $num > $self->{'last_box'};
    }
}

sub add_value {
    my ($self, $val, @boxes) = @_;
    my $use_hash = $self->{'use_hash'};
    for my $num (@boxes) {
	if ($use_hash) {
	    $self->{'container'}->{$num}->{$val} = 1;
	}
	else {
	    $self->{'container'}->[$num]->{$val} = 1;
	}
	$self->{'last_box'} = $num if $num > $self->{'last_box'}; # don't remember what this is used for
    }
}

sub add_range {
    my ($self, $first, $last, $val) = @_;
    add_value($self, $val, $first .. $last);
}

sub delete_range {
    my ($self, $first, $last, $val) = @_;
    delete_value($self, $val, $first .. $last);
}

1;
