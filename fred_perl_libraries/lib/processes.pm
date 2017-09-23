
package process;

my ($process, $children, $found);

sub ::get_children {
    use Proc::ProcessTable;
    $t = new Proc::ProcessTable;
    foreach $p (@{$t->table}) {
	$process->{$p->{pid}} = $p;
	push(@{$children->{$p->{ppid}}}, $p->{pid});
    }
    return find_children(@_);
}

sub find_children {
    my @result;
    for my $pid (@_) {
	for my $child (@{$children->{$pid}}) {
	    push(@result, $child) if ! $found{$child};
	    $found{$child} = 1;
	    push(@result, find_children($child));
	}
    }
    return @result;
}

1;
