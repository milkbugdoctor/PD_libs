
require 'misc.pl';

my $melting_params = "-Hdnadna -N0.05 -P0.00000005 -T1000 -B";

#
# annealing temperature stuff
#
my ($tm_pid, $tm_read, $tm_write);
sub get_tm {
    return -9999 if $_[0] eq '';
    return -9999 if $_[0] =~ /[^ACGT]/i;
    my $old = select $tm_write;
    $| = 1;
    select $old;
    print $tm_write "$_[0]\n";
    while (my $foo = read_line($tm_read)) {
	next if ! ($foo =~ /Melting temp/);
	return '' if ($foo =~ /zero/); # ZZZ huh?
	chomp;
	$foo =~ s/.*Melting temperature:\s+(\S+)\s.*/$1/;
	return $foo;
    }
}

sub start_tm_server {
    my ($params) = @_;
    $ENV{'NN_PATH'} = '/usr/local/share/MELTING4/NNFILES';
    $params = $melting_params if $params eq '';
    my $cmd = "/usr/local/bin/melting $params";
    $tm_pid = open2($tm_read, $tm_write, $cmd) || die "open2 $cmd";
}

sub kill_tm_server {
    close($tm_write);
}

1;
