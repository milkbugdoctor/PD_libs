package Choose;

#
#   Return all subsets of a given size.  Preserve set order.
#

use Carp;

#
#   my $choose = Choose::new(size, @set)
#
sub new {
    my ($size, @set) = @_;
    confess "size must be between 1 and the set size"
	if $size < 1 or $size > @set;
    my $self = [];
    bless $self;
    my @current = @set[0 .. $size - 1];
    push(@$self, \@set, \@current);
    return $self;
}

#
#   $choose->next() - returns @subset
#
sub next {
    my ($self) = @_;
    my ($set, $current) = @$self;
    my @result;
    if (@$current) {
	@result = @$current;
	# move somebody to the right
	for ($pos = $#{$current}; $pos >= 0; $pos--) {
	    my $num = @$set;
	    $current->[$pos] = ($current->[$pos] + 1) % $num;
	    last if $current->[$pos] != 0;
	}
	@$current = () if $pos < 0;
    }
    return @result if wantarray;
    return undef;
}

1;
