
my $debug = 0;

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
    my ($array, $value, $func, $first, $last) = @_;
    return -1 if @$array == 0;
    if (!defined($first)) {
	$first = 0;
	$last = $#{$array};
    }
    warn "binary_search($value, $first .. $last)\n" if $debug;
    die "bad range $first .. $last\n" if $first > $last;
    my $mid = int(($first + $last) / 2);
    my $cur = $func ? &$func($array->[$mid]) : $array->[$mid];
    warn "pos $mid val $cur\n" if $debug;
    if ($value < $cur) {
	my $next = $mid - 1;
	warn "$value < $cur, range $first .. $next\n" if $debug;
	return $first if $next < $first;
        return binary_search($array, $value, $func, $first, $next);
    }   
    elsif ($value > $cur) {
	my $next = $mid + 1;
	warn "$value > $cur, range $first .. $next\n" if $debug;
	return $last + 1 if $next > $last;
        return binary_search($array, $value, $func, $next, $last);
    }
    else {
	# we have found the value, now go to the left-most one
	while ($mid - 1 >= $first) {
	    my $cur = $func ? &$func($array->[$mid - 1]) : $array->[$mid - 1];
	    last if $cur != $value;
	    $mid = $mid - 1;
	}
        return $mid;
    }
}

if ($debug) {
    @foo = (1, 2, 2, 7, 9, 9, 15, 20);
    warn "list: foo @foo\n";
    print STDERR "enter number: ";
    while (<>) {
	my $val = $_ + 0;
	my $i = binary_search(\@foo, $val);
	warn "\ngot index $i for value $val\n\n";
	warn "list: foo @foo\n";
	print STDERR "enter number: ";
    }
}

1;
