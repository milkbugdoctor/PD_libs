#
# written by Fred Jon Edward Long
#

use POSIX ":sys_wait_h";
use IO::Handle;

sub timed_read {
    my ($file, $chars_wanted, $timeout) = @_;

    my ($rin, $rwin, $ein);
    $rin = $win = $ein = '';
    vec($rin, fileno($file), 1) = 1;
    $ein = $rin | $win;

    my $result;
    while (length($result) < $chars_wanted) {
	my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
	last if $nfound <= 0;
	if (vec($rout, fileno($file), 1)) {
	    my $foo;
	    if (sysread($file, $foo, 8192)) {
		$result .= $foo;
	    }
	}
    }
    return $result;
}

1;
