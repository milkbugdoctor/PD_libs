#
# written by Fred Long
#

my $debug = 0;

use POSIX ":sys_wait_h";
use IO::Handle;
use Fcntl ':flock'; # import LOCK_* constants
use Errno qw{EINTR EAGAIN};

my $bufsize = 128 * 1024;

#
#   Relay STDIN to socket and socket to STDOUT
#
#   FIX : replace with call to relay2
#
sub relay {
    my ($file, $do_debug, $timeout, $options) = @_;
    $debug = $do_debug;
    $byenow = 0;
    if ($timeout) {
	$SIG{ALRM} = 'relay_bye';
    }

    autoflush $file 1;
    autoflush STDOUT 1;

    my ($rin, $rwin, $ein);
    $rin = $win = $ein = '';
    vec($rin, fileno(STDIN), 1) = 1;
    vec($rin, fileno($file), 1) = 1;
    $ein = $rin | $win;

    while (1) {
	my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, undef);
	next if $nfound < 0 && $! == EINTR;
	die "select: $!" if $nfound < 0;
	last if $nfound == 0;
	return 1 if $byenow;
	if (vec($rout, fileno(STDIN), 1)) {
	    if ($f = sysread(STDIN, $foo, 8192)) {
		print $file $foo;
	    }
	    elsif ($options !~ /noeof/i) {
		warn "closing stdin because no more input\n" if $do_debug;
		close(STDIN);
		vec($rin, fileno(STDIN), 1) = 0;
		close_file(undef, $file, 1);
		$ein = $rin | $win;
		# wait for any response
		alarm($timeout) if $timeout;
	    }
	}
	if (vec($rout, fileno($file), 1)) {
	    if (sysread($file, $foo, 8192)) {
		print $foo;
	    }
	    else {
		warn "can't read any more from $file\n" if $do_debug;
		return 1;
	    }
	}
    }
    return 1;
}

#
#   Relay $in1 to $out1 and $in2 to $out2.
#
#   Options:
#       debug - print debugging info
#	no_close - don't close out1
#	exit_on_eof = exit on in1 EOF
#	exit_on_line = exit if we get line from in2
#       timeout - alarm timeout seconds for exit_on_*
#
sub relay2 {
    my ($in1, $out1, $in2, $out2, $options) = @_;

    my @in = ($in1, $in2);
    my @out = ($out1, $out2);
    for my $i (0, 1) {
	$out[$i]->autoflush(1);
    }

    my $timeout = $options->{timeout};
    my $no_close = $options->{no_close};
    my $do_debug = $options->{debug};
    my $exit_on_line = $options->{exit_on_line};
    my $exit_on_eof = $options->{exit_on_eof};
    my $exit_after_timeout;
    my $exit_after_flush;			# exit after we've written buffers to $out2

    my $old_debug = $debug;
    $debug = $do_debug;

    printf STDERR "got in[0] %s out[0] %s in[1] %s out[1] %s timeout $timeout noclose $no_close\n",
	fileno($in[0]), fileno($out[0]), fileno($in[1]), fileno($out[1]) if $debug;

    $byenow = 0;
    my $saved = $SIG{ALRM};
    $SIG{ALRM} = 'relay_bye' if $timeout;

    my ($rin, $rwin, $ein);
    $rin = $win = $ein = '';
    vec($rin, fileno($in[0]), 1) = 1;
    vec($rin, fileno($in[1]), 1) = 1;

    my @buffer;

    while (1) {
	for my $i (0, 1) { vec($win, fileno($out[$i]), 1) = ($buffer[$i] ne ''); }
	$ein = $win | $rin;
	check_files("rin win ein", $rin, $win, $ein) if $debug;
	my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, undef);
	check_files("rout wout eout", $rout, $wout, $eout) if $debug;
	last if $nfound == 0;
	last if $byenow;

	for my $file (@in, @out) {
	    my $fd = fileno($file);
	    if (vec($eout, $fd, 1)) {
		warn "got exception on fd $fd";
	    }
	}

	if (vec($rout, fileno($in[0]), 1)) {
	    if ($f = sysread($in[0], $foo, 8192)) {
		$buffer[0] .= $foo;
	    }
	    else {
		printf STDERR "EOF on in[0] fd %s\n", fileno($in[0]) if $debug;
		warn "closing in[0] $in[0]\n" if $debug;
		close_file($rin, $in[0], 0);
		close_file(undef, $out[0], 1) if ! $no_close;
		$ein = $win | $rin;
		# wait for any response
		if ($exit_on_eof) {
		    if ($timeout) {
			$exit_after_timeout = 1;
			alarm($timeout)
		    }
		    else {
			last;
		    }
		}
	    }
	}

	if (vec($rout, fileno($in[1]), 1)) {
	    my $foo;
	    if ((my $read = sysread($in[1], $foo, 8192)) <= 0) {
		warn "\nerror or EOF: got result [$read] from in[1]\n\n" if $debug;
		last;
	    }
	    $buffer[1] .= $foo;
	    if ($exit_after_timeout && $timeout) {
		alarm($timeout); # reset timeout
		warn "reset timeout alarm\n" if $debug;
	    }
	}

	for my $i (0, 1) {
	    if (vec($wout, fileno($out[$i]), 1) && $buffer[$i] ne '') {
		if ($i == 1 && $exit_on_line) {
		    if ($buffer[$i] =~ /^$exit_on_line$/m) {
			if ($timeout) {
			    $exit_after_timeout = 1;
			    alarm($timeout);
			    warn "got [$exit_on_line], waiting for idle timeout\n" if $debug;
			}
			else {
			    $exit_after_flush = 1;
			    warn "got [$exit_on_line], no timeout so leaving after buffers are flushed!\n" if $debug;
			}
		    }
		}
		my $len = length($buffer[$i]);
		my $sent = nonblocking_write($out[$i], $buffer[$i]);
		$buffer[$i] = substr($buffer[$i], $sent);
		if ($exit_after_timeout && $timeout) {
		    alarm($timeout); # reset timeout
		    warn "reset timeout alarm\n" if $debug;
		}
	    }
	}
	last if ($exit_after_flush && $buffers[1] eq '');
	last if $byenow;
    }
    $SIG{ALRM} = $saved;
    $debug = $old_debug;
    return 1;
}

sub multiplex_reader {
    my ($byline, $func, @files) = @_;
    my %status;

    my $open = 0;
    my ($rin, $win, $ein);
    for my $file (@files) {
	vec($rin, fileno($file), 1) = 1;
	$open++;
    }
    $ein = $rin | $win;

    while (1) {
	$bits = unpack("b*", $rin);

	if ((my $pid = waitpid(-1, WNOHANG)) > 0) {
	    $status{$pid} = $? >> 8;
	}
	my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, undef);
	last if $nfound <= 0;
	for my $file (@files) {
	    next if ! defined(fileno($file));
	    if (vec($eout, fileno($file), 1)) {
		printf STDERR "got error for $file %d\n", fileno($file); exit 1;
	    }
	    if (vec($rout, fileno($file), 1)) {
		if ($byline) {
		    my $line = <$file>;
		    if ($line ne '') {
			&$func($file, $line);
			next;
		    }
		}
		else {
		    my ($foo, $f);
		    if ($f = sysread($file, $foo, $bufsize)) {
			&$func($file, $foo);
			next;
		    }
		}
		vec($rin, fileno($file), 1) = 0;
		$ein = $rin | $win;
		close($file);
		# wait for any response
		# alarm($timeout) if $timeout;
		$open--;
	    }
	}
	last if $open <= 0;
    }
    return \%status;
}

sub multiplex_line_reader {
    return multiplex_reader(1, @_);
}

#
#   Copies input from $get_ref to all $wr_files
#   Multiplexes input from $rd_files to $got_ref
#
#   $get_ref  = function reference or file to read from
#   $wr_files = ref to list of files to write to
#   $rd_files = ref to list of files to read from
#   $got_ref  = function reference or file to write to
#
#   &$got_ref($file, $line, @_);
#
sub multiplex_reader_writer {
    my ($get_ref, $wr_files, $rd_files, $got_ref, $do_debug) = @_;
    my $old_debug = $debug;
    $debug = $do_debug;
    my (@wr_files) = @$wr_files;
    my (@rd_files) = @$rd_files;
    warn "calling multiplex_reader_writer\n" if $debug;
    my $pipe_handler = $SIG{'PIPE'};
    $SIG{'PIPE'} = 'IGNORE';	# doesn't seem to help Blat
    my $rd_open = 0;
    my ($rin, $win, $ein);
    for my $file (@$rd_files) {
	my $fileno = fileno($file);
	next if ! defined $fileno;
	vec($rin, $fileno, 1) = 1;
	$rd_open++;
    }
    vec($rin, fileno($get_ref), 1) = 1 if ref($get_ref) ne 'CODE';

    my $unsent_buf;
    my @buffers;
    my $last_rrr; # used for debugging
    while (1) {
	$rin_bits = unpack("b*", $rin);
	last if $rin_bits eq '';
	for my $file (@wr_files) {
	    my $fileno = fileno($file);
	    next if ! defined $fileno;
	    next if $buffers[0]{$file} eq '';
	    vec($win, $fileno, 1) = 1;
	}
	$ein = $rin | $win;
	check_files("rin win ein", $rin, $win, $ein) if $debug;
	my ($nfound, $timeleft) = select($rout=$rin, $wout=$win, $eout=$ein, undef);
	check_files("rout wout eout", $rout, $wout, $eout) if $debug;
	last if $nfound == 0;
	if ($nfound < 0) {
	    die "select error: $!";
	}

	my $rout_bits = unpack("b*", $rout);
	if ($debug) {
	    warn "$$ new rin    $rout_bits\n" if $last_rrr ne $rout_bits;
	    $last_rrr = $rout_bits;
	}

	if ($get_ref ne '') {	# get main input
	    if (ref($get_ref) eq 'CODE') {
		$unsent_buf = &$get_ref;
		undef $get_ref if $unsent_buf eq '';
	    }
	    elsif (defined(my $get_fd = fileno($get_ref))) {
		if (vec($rout, $get_fd, 1)) {
		    warn "\nreading from $get_fd/$get_ref\n" if $debug;
		    if (sysread($get_ref, $unsent_buf, $bufsize) <= 0) {
			warn "error reading from $get_fd/$get_ref\n" if $debug;
			vec($rin, $get_fd, 1) = 0;
			close $get_ref;
			undef $get_ref;
		    }
		    else {
			warn "OK reading from $get_fd/$get_ref:\n[$unsent_buf]\n\n" if $debug;
		    }
		}
	    }
	    else {
		die "don't know what to do with $get_ref";
	    }
	    if ($unsent_buf ne '') {
		for my $file (@wr_files) {
		    my $fd = fileno($file);
		    next if ! defined($fd);
		    $buffers[0]{$file} .= $unsent_buf;
		}
	    }
	}

	my $can_send = unpack("b*", $wout);
	if ($can_send) {
	    for my $file (@wr_files) {
		my $fd = fileno($file);
		next if ! defined($fd);
		next if length($buffers[0]{$file}) == 0;
		if (vec($eout, $fd, 1)) {
		    die "got error for $file $fd";
		}
		if (vec($wout, $fd, 1)) {
		    my $len = length($buffers[0]{$file});
		    my $sent = nonblocking_write($file, $buffers[0]{$file});
		    if (! defined $sent) {
			warn "got error '$!' on write to $file/$fd";
			close_file($win, $file, 1);
		    }
		    $buffers[0]{$file} = substr($buffers[0]{$file}, $sent) if $sent >= 0;
		}
	    }
	}

	my $unsent_bytes = 0;
	for my $file (@wr_files) {
	    my $fd = fileno($file);
	    next if ! defined($fd);
	    $unsent_bytes += length($buffers[0]{$file});
	}
	warn "\nunsent bytes $unsent_bytes (before reading)\n\n" if $debug;

	if (!defined($get_ref) && @wr_files && $unsent_bytes == 0) {	# no more input
		warn "\nno more input, shutting down all writable sockets\n" if $debug;
	    while (my $file = pop @wr_files) {
		close_file($win, $file, 1) if defined fileno($file);
	    }
	    warn "done shutting down all writable sockets\n\n" if $debug;
	}

	for my $file (@$rd_files) {
	    my $fd = fileno($file);
	    next if ! defined($fd);
	    if (vec($eout, $fd, 1)) {
		die "got error for $file $fd";
	    }
	    if (vec($rout, $fd, 1)) {
		my $input;
		warn "\nreading from socket $fd...\n" if $debug;
		if ((my $res = sysread($file, $input, $bufsize)) <= 0) {
		    warn "    EOF on $fd\n" if $debug && $res eq 0;
		    warn "    error [$!][$?] on $fd\n" if $debug && $res eq '';
		    close_file($rin, $file, 0);
		    $rd_open--;
		}
		warn "got from $file [$fd]:\n$input\n----\n\n" if $debug;
		$buffers[1]{$file} .= $input;
	    }
	}

	my $unwritten_bytes = 0;
	for my $file (@$rd_files) {
	    while ($buffers[1]{$file} =~ /.*\n/) {
		my $line = $&;
		$buffers[1]{$file} = substr($buffers[1]{$file}, length($line));

		if (ref($got_ref) eq 'CODE') {
		    printf STDERR "calling code to print %d bytes of data\n", length($line) if $debug;
		    &$got_ref($file, $line, @_);
		    if ($line eq '') {	# no more from this guy
			warn "\nZZZ got empty line, so we should wrap things up early for $file...\n\n" if $debug;
			$rd_open-- if close_file($rin, $file, 0);
		    }
		}
		elsif (defined(fileno($got_ref))) {
		    nonblocking_write($got_ref, $line);
		}
		else {
		    die "don't know what to do with $got_ref";
		}
	    }
	    $unwritten_bytes += length($buffers[1]{$file});
	    warn "unwritten $file:\n[$buffers[1]{$file}]\n\n" if $debug && $buffers[1]{$file} ne '';
	}
	warn "rd_open $rd_open, unwritten $unwritten_bytes\n" if $debug;
	last if $rd_open <= 0 && $unwritten_bytes == 0;
    }
    $SIG{'PIPE'} = $pipe_handler;
    $debug = $old_debug;
}

sub check_files {
    my $header = shift;
    my @names = split /\s+/, $header;
    for $vec (@_) {
	my $name = shift @names;
	printf STDERR "$name=";
	for my $i (0 .. 64) {
	    if (vec($vec, $i, 1)) {
		print STDERR "$i ";
	    }
	}
	print STDERR "\n";
    }
}

#
#   Copies input from $get_fh to all $wr_files.
#   Multiplexes input from $rd_files to $got_fh.
#   Prefixes output line by array index.
#
#   $get      = file or sub to read from
#   $wr_files = ref to list of files to write to
#   $rd_files = ref to list of files to read from
#   $got_fh   = file to write to
#
#   &$got_ref($file, $line, @_);
#
sub forked_multiplex_reader_writer {
    my ($get, $wr_files, $rd_files, $got_fh) = @_;

    # my $pipe_handler = $SIG{'PIPE'};
    # $SIG{'PIPE'} = 'IGNORE';

    for my $wr_fh (@$wr_files) {
	if (fork() == 0) {
	    if (ref($get) ne 'CODE') {
		my $fd = fileno($get);
		die "$get seems to be an invalid file handle" if ! defined $fd;
		my ($in, $buf);
		open($in, "<&$fd") || die "can't reopen $get";
		seek($in, 0, 0); # is this legal?
		while (<$get>) {
		    print $wr_fh $_ || die "can't write to $wr_fh";
		}
		close $in;
	    }
	    else {
		while ($_ = &$get) {
		    print $wr_fh $_ || die "can't write to $wr_fh";
		}
	    }
	    flush $wr_fh;
	    close_file(undef, $wr_fh, 1);
	    exit 0;
	}
    }

    for my $index (0..$#{$rd_files}) {
	if (fork() == 0) {
	    my $in = $rd_files->[$index];
	    while (<$in>) {
	        flock($got_fh, LOCK_EX) || warn "flock: $!";
		print $got_fh "$index\t$_" || die "can't write to $got_fh";
		flush $got_fh;
	        flock($got_fh, LOCK_UN) || warn "flock: $!";
	    }
	    exit 0;
	}
    }
    while (wait != -1) { }
    # $SIG{'PIPE'} = $pipe_handler;
}

sub close_file {
    my ($vec, $file, $direction) = @_;
    my $fd = fileno($file);
    warn "close_file($file, $direction), fd $fd\n" if $debug;
    if (defined $vec) {
	if (vec($_[0], $fd, 1) == 0) {
	    warn "bit for file already closed!?\n" if $debug;
	    return 0;
	}
	vec($_[0], $fd, 1) = 0;
    }
    warn "closing fd $fd dir $direction fileno $fd\n" if $debug;
    if (-S $file) {
	warn "    shutdown($fd, $direction)\n" if $debug;
        shutdown($file, $direction);
    }
    else {
	warn "    close($fd)\n" if $debug;
	close($file) || die "close($file) failed: $!";
    }
    return 1;
}

sub relay_bye {
    warn "got timeout alarm!\n" if $debug;
    $byenow = 1;
}

sub nonblocking_write {
    my ($file, $str) = @_;
    my $res = $file->blocking(0);
    my $sent = syswrite($file, $str, length($str));
    $res = $file->blocking(1);
    if ($sent < 1) {
	warn "got error '$!' on write to $file" if $debug;
    }
    return $sent;
}

1;
