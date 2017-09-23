
package PriorityQueue;

my $debug = 0;

#
#   new()
#
sub new {
    shift if $_[0] eq 'BinarySearch';	# allow BinarySearch->new()
    my $self = { };
    bless $self;
    $self->{array} = [ ];
    $self->{priorities} = [ ];
    return $self;
}

#
#   add(priority, item) -> index
#
sub add {
    my $self = shift;
    my $priority = shift;
    my $thing = shift;
    my $index = $self->find($priority, $thing);
    if ($index >= 0) {
	die "can't add, ($priority, $thing) exists at $index";
    }
    my $array = $self->{array};
    my $priorities = $self->{priorities};
    my $index = binary_search($array, $priorities, $priority);
    splice(@$array, $index, 0, $thing);
    splice(@$priorities, $index, 0, $priority);
    return $index;
}

#
#   get_lowest() -> (priority, item)
#
sub get_lowest {
    my $self = shift;
    my $array = $self->{array};
    my $priorities = $self->{priorities};
    return () if ($#$array == -1 || $#$priorities == -1);
    my $index = 0;
    my $item = splice(@$array, $index, 1);
    my $p = splice(@$priorities, $index, 1);
    return ($p, $item);
}

#
#   get_highest() -> (priority, item)
#
sub get_highest {
    my $self = shift;
    my $array = $self->{array};
    my $priorities = $self->{priorities};
    return () if ($#$array == -1 || $#$priorities == -1);
    my $index = $#$array;
    my $item = splice(@$array, $index, 1);
    my $p = splice(@$priorities, $index, 1);
    return ($p, $item);
}

#
#   delete(index)
#
sub delete {
    my $self = shift;
    my $index = shift;
    splice(@{$self->{array}}, $index, 1);
    splice(@{$self->{priorities}}, $index, 1);
}

#
#   find(priority[, thing]) -> index or -1
#
sub find {
    my $self = shift;
    my $priority = shift;
    my $thing = shift;
    my $array = $self->{array};
    my $priorities = $self->{priorities};
    my $index = binary_search($array, $priorities, $priority);
    return $index if ! defined $thing;
    while ($index <= $#$array) {
	my $cur = $priorities->[$index];
	return -1 if $cur != $priority;
	return $index if $thing eq $array->[$index];
	$index++;
    }
    return -1
}

#
#   print()
#
sub print {
    my $self = shift;
    my $array = $self->{array};
    my $priorities = $self->{priorities};
    my @result;
    for my $i (0 .. $#$priorities) {
	push(@result, sprintf "$i: (%s, %s)\n", $priorities->[$i], $array->[$i]);
    }
    return join("", @result);
}

#
#   Find place to insert given value.
#
#   Return -1 if $value < first element.
#
#       $array - array reference; array must be sorted
#	$value - value to search for
#	$func  - optional function to get value from array element
#
sub binary_search {
    my ($array, $priorities, $value, $first, $last) = @_;
    if (!defined($first)) {
	$first = 0;
	$last = $#{$array};
    }
    warn "binary_search($value, $first .. $last)\n" if $debug;
    return $first if $first > $last;
    my $mid = int(($first + $last) / 2);
    my $cur = $priorities->[$mid];
    warn "pos $mid val $cur\n" if $debug;
    if ($value < $cur) {
	my $next = $mid - 1;
	warn "$value < $cur, range $first .. $next\n" if $debug;
	return $first if $next < $first;
        return binary_search($array, $priorities, $value, $first, $next);
    }   
    elsif ($value > $cur) {
	my $next = $mid + 1;
	warn "$value > $cur, range $first .. $next\n" if $debug;
	return $last + 1 if $next > $last;
        return binary_search($array, $priorities, $value, $next, $last);
    }
    else {
	# we have found the value, now go to the left-most one
	while ($mid - 1 >= $first) {
	    my $cur = $priorities->[$mid - 1];
	    last if $cur != $value;
	    $mid = $mid - 1;
	}
        return $mid;
    }
}

if ($debug) {
    my $pq = new PriorityQueue();
    $pq->add(1, 1);
    $pq->add(2, 2);
    $pq->add(2, 2);
    $pq->add(7, 7);
    $pq->add(9, 9);
    $pq->add(15, 15);
    $pq->add(20, 20);
    my @p = @{$pq->{priorities}};
    my @foo = @{$pq->{array}};
    warn "list: [@p] [@foo]\n";
    print STDERR "enter number: ";
    while (<>) {
	my $val = $_ + 0;
	my $i = $pq->find($val);
	warn "\ngot index $i for value $val\n\n";
	warn "list: foo @foo\n";
	print STDERR "enter number: ";
    }
}

1;
