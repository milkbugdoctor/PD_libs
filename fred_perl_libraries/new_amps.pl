#!/usr/bin/perl

# $debug = 2;

#
# send commands to hit servers in parallel
#
# TODO: parallel connect

use IO::Handle;
use Errno qw(EAGAIN);

require 'primers.pl';
require 'misc.pl';
require 'tcp.pl';

$ENV{'CLASSPATH'} = "/home/flong/work/profile:" . $ENV{'CLASSPATH'};

my %connections;
my $server_name = "amp_server";

sub debug {
    if ($_[0] > 0) {
	my $d = shift(@_);
	print STDERR join('', @_), "\n" if $debug >= $d;
    }
    else {
	print STDERR join('', @_), "\n" if $debug;
    }
}

my @pids;

#
# change to select()
#
sub wait_for_results {
    my @commands = @_;
    my $result = "";
    while (@pids) {
debug(2, "waiting for $_...");
	while (waitpid($_, 0) != -1) { } # wait for commands to be sent
    }
debug(2, "done waiting commands to be sent");
    while (scalar(@commands) > 0) {
debug(3, "commands = @commands");
	for (my $i = 0; $i <= $#commands; $i++) {
	    my $si = $commands[$i];
	    my $r = $si->{"socket"};
	    my $chr = $si->{"chr"};
	    my $blocking = $r->blocking(0);
	    my $buf;
	    my $res = read($r, $buf, 10000);
	    $r->blocking($blocking);
	    next if $res eq '0'; # no data ready yet
	    if (! defined $res) {
		next if $! == EAGAIN;
printf STDERR "errno %d\n", $!;
		warn "got error [$!] on chr $chr\n";
		splice(@commands, $i, 1);
		next;
	    }
	    if ($res == 0) {
		debug(2, "got EOF on chr $chr");
		splice(@commands, $i, 1);
		next;
	    }
	    $si->{"result"} .= $buf;
debug(2, "got [$buf] from $chr");
	    my $tmp_res = $si->{"result"};
	    if ($tmp_res =~ /\n$/) {
debug(2, "wait_for_results: $chr is done");
		if (length($tmp_res) > 1) {
		    $result .= $chr . " " . $tmp_res;
		}
		splice(@commands, $i, 1);
debug(2, "wait_for_results: ", @commands+0, " more to go");
		last;
	    }
	}
    }
    return $result;
}

#
# $fd = chr_server_cmd($si, $chr, $cmd)
#
sub chr_server_cmd {
    my ($si, $chr) = @_;
    $si->{"result"} = "";
    my $fd = $si->{"socket"};
    my $cmd_len = length($_[2]);
    my $parallel = ($cmd_len > 25000);
    if ($parallel) {
	my $pid;
	if (($pid = fork()) == 0) {
	    # $fd->blocking(1);
	    print $fd $_[2];
	    $fd->flush;
	    exit 0;
	}
	else {
	    push(@pids, $pid);
	}
    }
    else {
	# $fd->blocking(1);
	print $fd $_[2] || die "print $!";
	$fd->flush;
    }
}

#
# $result = server_cmd($chr_only, $cmd)
#
# - send command to all chr servers, or just one
#
sub server_cmd {
    my ($chr_only) = @_;
    my @chrs = keys(%connections);
    my $result = "";
    my @commands;
    for my $chr (@chrs) {
	next if ($chr_only && $chr_only ne $chr);
	my $si = get_connection($chr);
	chr_server_cmd($si, $chr, $_[1]);
	push(@commands, $si);
    }
    return wait_for_results(@commands);
}

#
# $result = server_cmd2($chr_only, %chr_cmd)
#
# - send command to all chr servers, or just one
#
sub server_cmd2 {
    my ($chr_only, $chr_cmd) = @_;
    my @chrs = keys(%$chr_cmd);
    my $result = "";
    my @commands;

    for my $chr (@chrs) {
	next if ($chr_only && $chr_only ne $chr);
	next if ${$chr_cmd}{$chr} eq '';
	my $si = get_connection($chr);
	my $cmd = ${$chr_cmd}{$chr};
	chr_server_cmd($si, $chr, ${$chr_cmd}{$chr});
	push(@commands, $si);
    }
    return wait_for_results(@commands);
}

sub get_connections {
    for my $si (values(%connections)) {
	$si->{'socket'}->close;
    }

    my @servers = `show_servers | tail +2`;
    my $num;
    for my $line (@servers) {
	my ($chr, $host, $port) = split(/\t/, $line);
	$connections{$chr}{"chr"} = $chr;
	$connections{$chr}{"host"} = $host;
	$connections{$chr}{"port"} = $port;
	# my $fd = new FileHandle;
	my $fd = tcp_connect($host, $port) || die "couldn't connect to $host $port";
	$connections{$chr}{"socket"} = $fd;
	$num++;
    }
    die "no hit servers to connect to" if $num == 0;
}

get_connections;

sub clear_hits {
    return server_cmd("", "clear_hits\n");
}

sub store_hits {
    return server_cmd("", "store_hits\n" . join("\n", @_) . "\n\n");
}

#
#   Returns:
#	@foo	chromosomes
#	%foo	$foo{$chr}{$primer} -> pos
#
sub get_hits {
    local (*foo, @primers) = @_;
    undef %foo; undef @foo; undef $foo;
    for my $p (@primers) {
	for my $line (split(/\n/, server_cmd("", "get_hits $p\n"))) {
	    my ($chr, $res) = split(/ /, $line, 2);
	    $foo{$chr}{$p} = $res;
	    my $hits = scalar(split(/ /, $res));
	    $foo += $hits;
	}
    }
    @foo = keys %foo;
}

#
#	get_amp_info - get amplicon information
#
#	$chr         - chromosome name, or "" for all
#	$min         - minimum amplicon length
#	$max         - maximum amplicon length
#	$overlapping - consider overlapping amplicons?
#	$top         - consider only hits on top strand
#	@primers     - the list of primers
#
sub get_amp_info {
    my ($chr, $min, $max, $overlapping, $top, @primers) = @_;
    return server_cmd($chr,  "get_amp_info $min $max $overlapping $top\n" .
	join("\n", @primers) . "\n\n");
}

#
#	get_amps - get amplicons of a given length
#
#		min_amp	 - minimum amp length
#		max_amp	 - maximum amp length
#		overlap	 - can amplicons overlap?
#		restrict - restriction enzymes instead of PCR primers?
#	returns:
#		$foo - number of amplicons
#		@foo - list of amplicons
#		%foo - list of amplicons for each chromosome
#
sub get_amps {
    local (*foo, $min_amp, $max_amp, $overlap, $restrict, @primers) = @_;
    undef %foo; undef @foo; undef $foo;
    &read_amps(server_cmd("",  "get_amps $min_amp $max_amp $overlap $restrict\n" .
	join("\n", @primers) . "\n\n"));
}

sub read_amps {
    for my $line (split(/\n/, $_[0])) {
	chomp($line);
	next if $line =~ /ERROR/;
	$line =~ s/^(\S+) //;
	my $chr = $1;
	my @chr_hits;
	for my $amp (split(/\t/, $line)) {
	    my ($start, $len, @p) = split(/ /, $amp);
	    push(@chr_hits, sprintf("%d(%d)", $start, $len));
	    push(@foo, sprintf("%s %d %d %s %s", $chr, $start, $len, @p));
	    $foo++;
        }
        @chr_hits = sort { $a <=> $b } @chr_hits;
        $foo{$chr} = "@chr_hits" if @chr_hits;
    }
}

#
#	get positions covered by amp <= amp_len
#
#	allow amp overlaps (right?)
#
sub get_covered {
    local (*foo, $amp_len, $min_cover, $overlap, $first, $top, $primers, $positions, $by_chr) = @_;
    undef %foo; undef @foo; undef $foo;
    my %chr_cmd;
    my $start = time;

    return if (@$primers == 0);

    for my $chr (keys(%connections)) {
	if (${$positions}{$chr}) {
	    $chr_cmd{$chr} = "get_markers_covered $amp_len $min_cover $overlap $first $top\n"
		. join("\n", @$primers) . "\n" . ${$positions}{$chr} . "\n";
	}
    }
    for my $line (split(/\n/, server_cmd2("", \%chr_cmd))) {
	chomp($line);
	next if $line =~ /ERROR/;
	$line =~ s/^chr(\S+) //;
	my $chr = $1;
	for my $amp (split(/\t/, $line)) {
	    my ($marker, $start, $end, @p) = split(/ /, $amp);
	    if ($by_chr) {
		if ($foo{$chr}) {
		    $foo{$chr} .= " $marker";
		}
		else {
		    $foo{$chr} = "$marker";
		}
		# @chr_hits = sort { $a <=> $b } @chr_hits;
	    }
	    push(@foo, join("\t", $chr, $marker, $start, $end, @p));
	    $foo++;
        }
    }
}

sub get_snps_covered {
    my $start = time;
    local (*foo, $amp_len, $primers, $positions, $by_chr) = @_;
    return get_covered(*foo, $amp_len, 1, 1, 1, 0, $primers, $positions, $by_chr);
}

sub get_connection {
    my $chr = $_[0];
    my $si = $connections{$chr};
    return $si if $si;
    if ($chr =~ /^chr/) {
	$chr =~ s/^chr//;
	return $connections{$chr};
    }
    else {
	return $connections{"chr$chr"};
    }
}

sub get_seq {
    my ($chr, $pos, $len) = @_;
    my $res = server_cmd($chr, "get $pos $len\n");
    my $seq = (split(/\s+/, $res))[1];
    return $seq;
}

#
#	get_similar("sequence", max_mismatch)
#
sub get_similar {
    return server_cmd("", "get_similar @_\n");
}

#
#	get_num_word_hits("sequence")
#
sub get_num_word_hits {
    return server_cmd("", "get_num_word_hits @_\n");
}

1;
