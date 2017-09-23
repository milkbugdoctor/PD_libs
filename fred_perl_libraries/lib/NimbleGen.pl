#!/usr/bin/perl

require 'probes.pl';
require 'misc.pl';

package NimbleGen;

$max_rounds = 148;

my @order = qw/A C G T/;


my $probe_len = 50;

#
#   Return list of "$offset $probe_seq"
#
sub 'build_probes {
    my ($seq, $probes_per_seq) = @_;
    my @good_probes;
    for (my $i = 0; $i <= length($seq) - $probe_len; $i++) {
	my $probe = substr($seq, $i, $probe_len);
	next if ($probe =~ /[Nacgt]/);
	if (&good_probe($probe)) {
	    push(@good_probes, "$i $probe");
	}
    }
    return ::trim_probes($probes_per_seq, @good_probes) if $probes_per_seq;
    return @good_probes;
}

#
#   Return list of "$offset $probe_seq"
#
sub all_good_probes {
    my ($seq, $allow_lowercase) = @_;
    my @good_probes;
    for (my $i = 0; $i <= length($seq) - $probe_len; $i++) {
	my $probe = substr($seq, $i, $probe_len);
        next if ($probe =~ /^[ACGT]/i);
	next if !$allow_lowercase and ($probe =~ /[acgt]/);
	if (&good_probe($probe)) {
	    push(@good_probes, "$i $probe");
	}
    }
    return @good_probes;
}

###################################################################

#
#   Probes are built up from the 3' end
#
sub get_longest_tagged_probe {
    my ($tag1, $seq, $tag2) = @_;
    $seq = get_longest_good_probe($seq . $tag2);
    $seq = substr($seq, 0, length($seq) - length($tag2));
    while (1) {
	return $seq if good_probe($tag1 . $seq . $tag2);
	$seq = substr($seq, 1);
    }
}

#################################
#				#
#   Fred's cool caching stuff   #
#				#
#################################

my $tile_len = 7;
my %seq_cache;

sub get_longest_good_probe {
    my ($seq, $cycles, $max_len) = @_;
    $cycles = $max_rounds if $cycles == 0;
    my $rounds = 0;
    my $rev = reverse "\U$seq";
    my $last = '';
    my $len = length($rev);
    my $result_len;
    for (my $i = 0; $i < $len; $i++) {
	my $cur = substr($rev, $i, 1);
	last if $cur !~ /[ACGT]/;
	my $pair = $last . $cur;
	$rounds += $seq_cache{$pair};
	last if $rounds > $cycles;
	$result_len++;
	if ($max_len > 0 && $result_len >= $max_len) {
	    $result_len = $max_len;
	    last;
	}
	$last = $cur;
    }
    return substr($_[0], -$result_len);
}

sub good_probe {
    my ($seq) = @_;
    my $rounds = 0;
    return 0 if $seq =~ /[^ACGT]/i;
    $seq = "\U$seq";
    my $rev = reverse $seq;
    my $last = '';
    my $len = length($rev);
    for (my $i = 0; $i < $len; $i += $tile_len) {
	$rounds += $seq_cache{$last . substr($rev, $i, 1)};
	return 0 if $rounds > $max_rounds;
	last if $i == $len - 1;
	$rounds += $seq_cache{substr($rev, $i, $tile_len)};
	return 0 if $rounds > $max_rounds;
	$last = substr($rev, $i + $tile_len - 1, 1);
    }
    return 1;
}

sub get_cycles {
    my ($seq) = @_;
    my $rounds = 0;
    die "Illegal char [$&] found in [$seq]\n" if $seq =~ /[^ACGT]/i;
    $seq = "\U$seq";
    my $rev = reverse $seq;
    my $last = '';
    my $len = length($rev);
    for (my $i = 0; $i < $len; $i += $tile_len) {
	$rounds += $seq_cache{$last . substr($rev, $i, 1)};
	last if $i == $len - 1;
	$rounds += $seq_cache{substr($rev, $i, $tile_len)};
	$last = substr($rev, $i + $tile_len - 1, 1);
    }
    return $rounds;
}

sub next {
    my ($seq) = @_;
    for ($pos = length($seq) - 1; $pos >= 0; $pos--) {
        substr($seq, $pos, 1) =~ tr/ACGT/CGTA/;
        last if substr($seq, $pos, 1) ne 'A';
    }
    return "" if $pos < 0;
    return $seq;
}

sub cache_seq {
    my ($rev) = @_;
    my $rounds = 0;
    my $trans = $rev;
    $trans =~ tr/ACGT/0123/;
    my @list = split //, $trans;
    unshift(@list, -1) if @list == 1;
    for (my $i = 0; $i < $#list; $i++) {
	my ($a, $b) = @list[$i, $i + 1];
	$rounds += ($b + 4 - $a - 1) % 4 + 1;
    }
    $seq_cache{$rev} = $rounds;
}

sub load_cache {
    for my $len (1 .. $tile_len) {
	my $seq = 'A' x $len;
	do {
	    cache_seq($seq);
	}
	while ($seq = &next($seq));
    }
}

load_cache;

1;
