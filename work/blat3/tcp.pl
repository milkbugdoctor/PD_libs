##############################################################################
#
#   tcp.pl - TCP and UDP stuff for Perl 5
#
##############################################################################

use Socket;

#
# &tcp_connect(host, port)
#
sub tcp_connect {
	my ($host, $port) = @_;

        my $fd;

	if ($port eq "" || $host eq "") {
		print STDERR "Usage: &tcp_connect(FILE, 'machine', port)\n";
		return 0;
	}

	my $hostname;
	chop($hostname = `hostname`);

	my ($name, $al, $proto) = getprotobyname('tcp');
	$port = (getservbyname($port, 'tcp'))[2] unless $port =~ /^\d+$/;
	if ($port eq "") {
		print STDERR "Bad port \"$_[2]\"\n";
		return undef;
	}
	my ($name, $al, $type, $len, $thisaddr) = gethostbyname($hostname);
	(($name, $al, $type, $len, $thataddr) = gethostbyname($host)) || do {
		print STDERR "Can't get address for host \"$host\"\n";
		return undef;
	};

	socket($fd, PF_INET, SOCK_STREAM, $proto) || do {
		print STDERR "socket() failed: $!\n";
		return undef;
	};

	$that = sockaddr_in($port, $thataddr);
	if ($< != 0) {
		$this = sockaddr_in(0, $thisaddr);
		bind($fd, $this) || do {
			print STDERR "bind() failed: $!\n";
			return undef;
		}
	}
	else {
		for ($my_port = 1023; $my_port >= 1; $my_port--) {
			$this = sockaddr_in($my_port, $thisaddr);
			last if bind($fd, $this);
		}
		if ($my_port == 0) {
			print STDERR "No more ports less than 1024\n";
			return undef;
		}
	}

	connect($fd, $that) || do {
		print STDERR "connect($host, $port) failed: $!\n";
		close($fd);
		return undef;
	};

	$tmp = select($fd);
	$| = 1; select($tmp);

	return $fd;
}


#
# &ucp_connect(FILE, host, port)
#
sub udp_connect {

	my ($fd, $host, $port) = @_;

	if ($port eq "" || $host eq "") {
		print STDERR "Usage: &udp_connect(FILE, 'machine', port)\n";
		return 0;
	}

	my $sockaddr = 'S n a4 x8';
	my $hostname;
	chop($hostname = `hostname`);

	my ($proto, $thisaddr, $thataddr);
	$proto = (getprotobyname('udp'))[2];
	$port = (getservbyname($port, 'udp'))[2] unless $port =~ /^\d+$/;
	$thisaddr = (gethostbyname($hostname))[4];
	$thataddr = (gethostbyname($host))[4] || do {
		print STDERR "Can't get address for host \"$host\"\n";
		return 0;
	};

	my ($this, $that);
	$this = sockaddr_in(0, $thisaddr);
	$that = sockaddr_in($port, $thataddr);

	# socket($fd, 2, 2, $proto) || do {
	socket($fd, 2, 2, 0) || do {
		print STDERR "socket() failed: $!\n";
		return 0;
	};
	bind($fd, $this) || do {
		print STDERR "bind() failed: $!\n";
		return 0;
	};
	connect($fd, $that) || do {
		print STDERR "connect() failed: $!\n";
		close($fd);
		return 0;
	};

	return 1;
}

sub print_addr {
	@foo = split(//, $_[0]);
	for $i (@foo) {
		printf "%x ", $i;
	}
	print "\n";
}

1;
