##############################################################################
#
#   misc.pl - Miscellaneous functions for Perl 4
#
##############################################################################

use Carp;
use FileHandle;
use IPC::Open2;
# require 'open2.pl';

#
#    shell(@args)
#
#    Does NOT ignore INT and KILL signals, unlike system(),
#    which makes the parent ignore INT and KILL.
#
#    Returns true if successful.
#
sub shell {
    if (fork() == 0) {
	exec @_;
	die "exec @_ failed!: $!";
    }
    wait;
    return ($? >>= 8) == 0;
}

#
#    command('command args', 'input for command');
#
#    Does NOT ignore INT and KILL signals, unlike system(),
#    which does make the parent ignore INT and KILL.
#
sub command {
    my ($cmd, $input) = @_;
    my ($write_handle, $read_handle);
    (my $pid = open2($read_handle, $write_handle, $cmd)) || die "open2";
    print $write_handle $input;
    close($write_handle);
    while (<$read_handle>) {
	print $_;
    }
    waitpid $pid, 0;
    return ($? >>= 8);
}

#	$fd = cmd('command args', 'input for command');
sub cmd_reader {
	my ($cmd, $input) = @_;
	my ($write_handle, $read_handle);
	(my $pid = open2($read_handle, $write_handle, $cmd)) || die "open2";
	print $write_handle $input;
	close($write_handle);
	return $read_handle;
}

#
#	cmd('command args', 'input for command');
#
#	- input must be short enough to not cause blocking and deadlock
#
sub cmd {
	my ($cmd, $input) = @_;
	my ($write_handle, $read_handle);
	(my $pid = open2($read_handle, $write_handle, $cmd)) || die "open2";
	print $write_handle $input;
	close($write_handle);
	my @result = <$read_handle>;
	waitpid $pid, 0;
	$? >>= 8;
	return @result;
}

sub cmd_string {
    return join('', &cmd(@_));
}


#
#   read_line(file_handle, no_chomp)
#
#   Read one line and that's it, no read-ahead.
#
sub read_line {
    my $read_handle = shift;
    my $no_chomp = shift;
    my ($res, $read);
    while ($read = sysread($read_handle, $foo, 1)) {
        if ($foo eq "\n") {
	    $res .= $foo if $no_chomp;
	    last;
	}
        $res .= $foo;
    }
    defined $read || die "read_line($read_handle) failed [$!] [$?]";
    return $res;
}

sub min {
	return $_[0] < $_[1] ? $_[0] : $_[1];
}

sub max {
	return $_[0] > $_[1] ? $_[0] : $_[1];
}

sub Min {
    my $min = shift @_;
    for my $i (@_) {
        $min = $i if $i < $min;
    }
    return $min;
}

sub Max {
    my $max = shift @_;
    for my $i (@_) {
        $max = $i if $i > $max;
    }
    return $max;
}

#
# convert space to tab
#
sub print_tabbed {
    my ($fd, $string) = @_;
    $string =~ s/ /\t/g;
    print $fd $string || die "print fd $fd string $string";
}

#
#    0-based
#
sub get_file_seq {
    my ($file, $start, $len) = @_;
    confess "negative length [$len]" if $len < 0;
    return '' if $len == 0;
    $fh = new FileHandle;
    open($fh, $file) || die "couldn't open $file";
    seek($fh, $start, 0) || die "couldn't seek to '$start' in $file";
    read($fh, $seq, $len) || die "couldn't read $len bytes from $file at $start: $!";
    return $seq;
    close($fh);
}

#
#    0-based
#
sub get_file_seq_circular {
    my ($file, $start, $len) = @_;
    my $size = get_file_size($file);
    $start = ($start + $size) % $size;
    if ($start < 0) {
	my $seq1 = get_file_seq_circular($file, $size - abs($start), abs($start));
	my $seq2 = get_file_seq_circular($file, 0, $len - abs($start));
	return $seq1 . $seq2;
    }
    my $seq = get_file_seq($file, $start, $len);
    $seq .= get_file_seq($file, 0, ($len - length($seq))) if (length($seq) < $len);
    return $seq;
}

#
#    0-based
#
sub print_file_seq {
    my ($fd, $file, $start, $len) = @_;
    $fh = new FileHandle;
    open($fh, $file) || die "couldn't open file '$file'";
    seek($fh, $start, 0) || die "couldn't seek to '$start' in $file";
    my $bufsize = 1024 * 1024;
    while ($len > 0) {
	$bufsize = $len if $len < $bufsize;
	read($fh, $seq, $bufsize) || die "couldn't read $bufsize bytes from $file at $start";
	print $fd $seq;
	$len -= length($seq);
    }
    close($fh);
}


#
#   For signals cleanup routine will be performed twice
#
#   Use global variables, 'my' vars don't work for some reason
#
sub cleanup_setup {
    my $sub = "cleanup_sub_$$";
    my $pid = $$;
    $SIG{TERM} = $sub;
    $SIG{INT}  = $sub;
    $SIG{HUP}  = $sub;
    $SIG{KILL} = $sub;
    $SIG{QUIT} = $sub;
    eval "
	sub $sub {
	    my \$status = \$?;
	    return 0 if $pid != \$\$;
	    do { $_[0] };
	    exit (\@_ or \$status); # \@_ is for signals
	}
	END { &$sub; }
    ";
}

#
#   Get name for tmpfile but don't open it.
#
sub get_tmpfile {
    my ($dir, $prefix) = @_;
    $dir = "/tmp" if $dir eq '';
    $prefix = "tmp" if $prefix eq '';
    while (1) {
	my $rnd = rand 100000;
	my $time = time;
	my $filename = "$dir/$prefix.$rnd.$time.$$";
	next if -e  $filename;
	return $filename;
    }
}

#
#   Open new tmpfile.
#
sub open_tmpfile {
    my $filename = &get_tmpfile;
    my $fh;
    open($fh, ">$filename") || die "open_tmpfile: $!";
    return ($fh, $filename);
}

#
#   Wait for a certain number of seconds.
#
sub delay {
    my ($seconds) = @_;
    my ($rd, $wr, $err);
    select($rd, $wr, $err, $seconds);
}

sub get_file_handle {
    my ($fd) = @_;
    if (eval { ref(*{$fd}{IO}) } =~ /^FileHandle$/) {
	return *{$fd}{IO};
    }
    elsif (eval { ref(*{$fd}{IO}) } =~ /^IO::Handle$/) {
	return $fd;
    }
    elsif (eval { ref(*{$fd}{IO}) } =~ /^IO::File$/) {
	return $fd;
    }
    return undef;
}

#
#   Return unique members of list.
#
sub hash_unique {
    my (@list) = @_;
    my %hash;
    for my $p (@list) { $hash{$p} = $p; }
    return values %hash;
}

sub randomize_list {
    my @list = @_;
    for my $i (0 .. $#list) {
        my $r = int(rand @list);
        ($list[$i], $list[$r]) = ($list[$r], $list[$i]);
    }
    return @list;
}

sub get_file_size {
    my $fd = new IO::File;
    $fd->open("< $_[0]") or die "cannot open '$_[0]'";
    $fd->seek(0, 2) or die "cannot seek: $!";
    return tell($fd);
}

sub round_to {
    my ($val, $multiple) = @_;
    return int($val / $multiple + .5) * $multiple;
}

sub get_stack {
    my ($skip) = @_;
    $skip = 1 if $skip < 1;
    my $str;
    for (my $i = $skip; ; $i++) {
        my @foo = caller($i);
        last if @foo == 0;
	$str .= sprintf "\t%-24s %s line %s\n", $foo[3], $foo[1], $foo[2];
    }
    $str = "stack:\n" . $str if $str ne '';
}

sub warn2 {
    print STDERR @_;
    print STDERR "\n";
    print STDERR get_stack(2);
}

sub die2 {
    print STDERR @_;
    print STDERR "\n";
    print STDERR get_stack(2);
    exit 1;
}

sub call_level {
    for (my $i = 0; ; $i++) {
        my @foo = caller($i);
        return $i - 1 if @foo == 0;
    }
}

sub debug {
    my $str = join('', @_);
    print STDERR "    " x (&call_level - 1) . $str;
    print STDERR "\n" if substr($str, -1) ne "\n";
}

1;
