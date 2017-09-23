#!/usr/bin/perl

#
# old - build amps here, in the client
#

require 'primer.pl';

my $slice_size = 200;

#
#	globals: @chrs, @seq, %map
#

sub merge_hits {
    my ($c, @primers) = @_;
    my (%amps, $num, @hits);
    my $num = 0;
    for my $p (@primers) {
	for my $hit (unpack('I*', $map{$p}{$c})) {
	    push(@hits, "${hit}L$num");
	}
	my $len = length($p);
	my $rc = rc($p);
	for my $hit (unpack('I*', $map{$rc}{$c})) {
	    push(@hits, "${hit}R$len $num");
	}
	$num++;
    }
    return sort { $a <=> $b } @hits;
}

#
#	get non-overlapping amps shorter than a given length
#
sub get_amps {
    local (*foo, $amp_len, @primers) = @_;
    undef %foo; undef @foo; undef $foo;
    for my $c (@chrs) {
	my @hits = merge_hits($c, @primers);
	my ($last, @chr_hits);
	for my $hit (@hits) {
	    if ($last =~ /L/ && $hit =~ /R(\d+) (\d+)$/) {
		my $right = $hit + $1;
		my $right_primer = $2;
		$last =~ /L(\d+)/;
		my $left_primer = $1;
		if ($right - $last <= $amp_len) {
		    push(@chr_hits, sprintf("%d(%d)", $last, $right - $last));
		    push(@foo, sprintf("%s %d %d %s %s", $c, $last, $right - $last,
			$primers[$left_primer], $primers[$right_primer]));
		    $foo++;
		}
	    }
	    $last = $hit;
	}
	@chr_hits = sort { $a <=> $b } @chr_hits;
	$foo{$c} = "@chr_hits" if @chr_hits;
    }
}

#
#	get all (overlapping) amps shorter than a given length
#
sub get_overlapping_amps {
    local (*foo, $amp_len, @primers) = @_;
    undef %foo; undef @foo; undef $foo;
    for my $c (@chrs) {
	my @hits = merge_hits($c, @primers);
	my ($last, @chr_hits);
	for (my $h = 0; $h <= $#hits; $h++) {
	    my $hit = $hits[$h];
	    next if ! ($hit =~ /R(\d+) (\d+)$/);
	    my $right = $hit + $1;
	    my $right_primer = $2;
	    for ($l = $h - 1; $l >= 0; $l--) {
		$last = $hits[$l];
	        next if ! ($last =~ /L(\d+)/);
		my $left_primer = $1;
		last if ($right - $last > $amp_len);
		push(@chr_hits, sprintf("%d(%d)", $last, $right - $last));
		push(@foo, sprintf("%s %d %d %s %s", $c, $last, $right - $last,
		    $primers[$left_primer], $primers[$right_primer]));
		$foo++;
	    }
	}
	@chr_hits = sort { $a <=> $b } @chr_hits;
	$foo{$c} = "@chr_hits" if @chr_hits;
    }
}


#
#	get positions covered by amp <= amp_len
#
#	allow amp overlaps (right?)
#
sub get_covered {
    local (*foo, $amp_len, $primers, $pos_hash, $by_chr) = @_;
    undef %foo; undef @foo; undef $foo;
    for my $c (@chrs) {
	my @hits = merge_hits($c, @$primers);
	my @array = unpack('I*', ${$pos_hash}{$c});
	for my $pos (@array) {
	    push(@hits, "${pos}P");
	}
	@hits = sort { $a <=> $b } @hits;
	my @chr_hits;
	my ($left, $right);
	for (my $i = 0; $i <= $#hits; $i++) {
	    my $pos = $hits[$i];
	    if ($pos =~ /P$/ && ($pos - $left) <= $amp_len) {
		for (my $j = $i + 1; $j <= $#hits; $j++) {
		    my $hit = $hits[$j];
		    last if $hit - $left > $amp_len;
		    next if ! ($hit =~ /R(\d+)/);
		    my $right = $hit + $1;
		    if ($right - $left <= $amp_len) {
			push(@chr_hits, sprintf("%d", $pos + 0)) if $by_chr;
			push(@foo, sprintf("%s:%d:%d-%d", $c, $pos, $left, $right-1));
			$foo++;
		    }
		    last;
		}
	    }
	    if ($pos =~ /L/) {
		$left = $hits[$i];
	    }
	}
	if ($by_chr) {
	    @chr_hits = sort { $a <=> $b } @chr_hits;
	    $foo{$c} = "@chr_hits" if @chr_hits;
	}
    }
}

#
# sets %map, @chrs, @seq
#
# uses rc for bottom hits too
#
sub get_hits {
    %map = ();
    @chrs = ();
    @seq = ();
    if (@_ == 0) {
	return 1;
    }
    my %keys;
    for my $p (@_) { $keys{$p} = 1; $keys{rc($p)} = 1; }
    my @keys = keys(%keys);
    my @slice;
    local (%chr, %seq);
    while (@slice = splice(@keys, 0, $slice_size)) {
	open(FOO, "query @slice |") || die "query";
	die "query $! $?" if ($? != 0);
	&read_map(FOO);
    }
    @seq = keys %seq;
    @chrs = keys %chr;
    return 1;
}

#
# sets %chr, %seq, %map
#
sub read_map {
    my $fd = $_[0];
    while (<$fd>) {
	chomp;
	next if /ERROR/;
	my ($seq, $chr, $pos) = split(/\t/, $_);
	$chr{$chr} = 1;
	$seq{$seq} = 1;
	$map{$seq}{$chr} = pack('I*', split(/ /, $pos));
    }
    close(FOO);
}

#
# no auto rc
#
sub get_chr_hit_array {
    my (@result, %keys, %chr, %seq);
    open(FOO, "chr_query @_ |") || die "chr_query";
    while (<FOO>) {
	chomp;
	my ($seq, $chr, $pos) = split(/\t/, $_);
	my (@pos) = split(/ /, $pos);
	for my $p (@pos) { push(@result, "$seq\t$chr\t$p"); }
    }
    close(FOO);
    return @result;
}

1;
