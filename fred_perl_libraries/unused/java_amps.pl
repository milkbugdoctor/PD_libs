#!/usr/bin/perl

#
# use java Hits program to send commands to hit servers in parallel
#

require 'primer.pl';
require 'misc.pl';
require 'mysql.pl';

$ENV{'CLASSPATH'} = "/home/flong/work/profile:" . $ENV{'CLASSPATH'};

my ($write_handle, $read_handle, $pid);
my $cmd = "java Hits";

sub init {
    return if $pid ne '';
    $pid = open2($read_handle, $write_handle, $cmd) || die "open2 $cmd";
}

sub read_lines {
    my $res;
    while (1) {
	my $line = read_line($read_handle);
	$res .= $line;
	last if $line eq "";
    }
    return $res;
}

sub get_hits {
    init;
    print $write_handle "store_hits\n", join("\n", @_), "\n\n";
    return read_line($read_handle);
}

sub print_hits {
    init;
    print $write_handle "print_hits\n", join("\n", @_), "\n\n";
    return read_lines($read_handle);
}

sub read_amps {
    my $line;
    while (($line = read_line) ne '') {
	chomp;
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
#	get all amps of a given length
#
#           min_amp  - minimum amplicon length
#           max_amp  - maximum amplicon length
#           overlap  - consider overlapping amplicons (0 or 1)
#           restrict - restriction enzymes instead of PCR primers (0 or 1)
#
sub get_amps {
    local (*foo, $min_amp, $max_amp, $overlap, $restrict, @primers) = @_;
    undef %foo; undef @foo; undef $foo;
    init;
    print $write_handle "get_amps $min_amp $max_amp $overlap $restrict\n", join("\n", @primers), "\n\n";
    &read_amps;
}

#
#	get positions covered by amp <= amp_len
#
#	allow amp overlaps (right?)
#
sub get_covered {
    local (*foo, $amp_len, $primers, $positions, $by_chr) = @_;
    undef %foo; undef @foo; undef $foo;
    init;
    print $write_handle "get_snps_covered $amp_len\n"
	. join("\n", @primers) . "\n$positions\n";

    my $line;
    while (($line = read_line) ne '') {
	chomp;
	next if $line =~ /ERROR/;
	$line =~ s/^chr(\S+) //;
	my $chr = $1;
	for my $amp (split(/\t/, $line)) {
	    my ($start, $pos, $end, @p) = split(/ /, $amp);
	    if ($by_chr) {
		if ($foo{$chr}) {
		    $foo{$chr} .= " $pos";
		}
		else {
		    $foo{$chr} = "$pos";
		}
		# @chr_hits = sort { $a <=> $b } @chr_hits;
	    }
	    push(@foo, sprintf("%s:%d:%d-%d", $chr, $pos, $start, $end));
	    $foo++;
        }
    }
}

1;
