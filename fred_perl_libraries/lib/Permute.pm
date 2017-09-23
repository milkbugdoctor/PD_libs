package Permute;

#
#   Return the cross product of a list of sets.
#

use Carp;

#
#   my $permute = Permute::new(@permutations)
#
#	@permutations: array of sets (array refs)
#
sub new {
    my (@permutations) = @_;
    for my $i (0 .. $#permutations) {
	confess "nothing at position $i: [$permutations[$i]]" if @{$permutations[$i]} == 0;
    }
    my $self = [];
    bless $self;
    my @current = (0) x @permutations;
    push(@$self, \@permutations, \@current);
    return $self;
}

#
#   $permute->next() - returns @row
#
sub next {
    my ($self) = @_;
    my ($permutations, $current) = @$self;
    my @result;
    if (@$current) {
	confess "huh?" if @$current != @$permutations;
	for my $i (0 .. $#{$current}) {
	    my $j = $current->[$i];
	    push(@result, $permutations->[$i][$j]);
	}
	for ($pos = $#{$current}; $pos >= 0; $pos--) {
	    my $num = @{$permutations->[$pos]};
	    $current->[$pos] = ($current->[$pos] + 1) % $num;
	    last if $current->[$pos] != 0;
	}
	@$current = () if $pos < 0;
    }
    return @result if wantarray;
    return undef;
}

1;
