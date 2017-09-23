#!/usr/bin/perl

require 'primers.pl';
require 'sequences.pl';
require 'binary_search.pl';

#
#	TaqMan straddle probes
#
#	no G at 5'
#	no 4x repeats
#	tm 64-66 degrees
#	one probe per allele
#	can use either strand
#	snp should be in middle 1/3
#
sub get_taqman_probe {
    my ($left, $allele, $right, $low_tm, $high_tm) = @_;
    my $mid_tm = ($high_tm + $low_tm)/2;
    my $seq = $left . $allele . $right;
    my $seq_len = length($seq);
    my $snp_pos = length($left);
    my $best_weight = 99999;
    my @best = ("none", "none", "none", "none", "none");
    for (my $strand = 0; $strand <= 1; $strand++) {
	my $ll = $strand ? rc($left) : $left;
	my $rr = $strand ? rc($right) : $right;
	for (my $len = 20; $len <= 60; $len++) {
	    for (my $pos = $snp_pos - $len + 1; $pos <= $snp_pos; $pos++) {

		# next if $pos + $len <= $snp_pos;
		next if $pos + $len > $seq_len;
		my $probe = substr($seq, $pos, $len);

		next if ($probe =~ /^G/i);

		next if ($probe =~ /GGGG/i);

		my $rel_snp_pos = ($snp_pos - $pos) / $len;
		next if $rel_snp_pos < .33 || $rel_snp_pos > .67;

		# my $gc = gc_content($probe);
		# next if ($gc < .3 || $gc > .8);

		my $A_len = ($probe =~ /A+/) && length($&);
		my $C_len = ($probe =~ /C+/) && length($&);
		my $G_len = ($probe =~ /G+/) && length($&) * 3;
		my $T_len = ($probe =~ /T+/) && length($&);
		my $max_poly = $A_len;
		$max_poly = $C_len if $C_len > $max_poly;
		$max_poly = $G_len if $G_len > $max_poly;
		$max_poly = $T_len if $T_len > $max_poly;

		my $tm = get_tm($probe);
		next if $tm < $low_tm;
		next if $tm > $high_tm;
		my $tm_diff = abs($tm - $mid_tm);
		my $wt = $tm_diff + $max_poly;
		if ($wt < $best_weight) {
		    $best_weight = $wt;
		    @best = ($probe, $pos, $len, $strand, $tm, $wt);
		}
	    }
	}
    }
    return @best;
}

#
#   Get intron/exon probes
#
#   Returns list of array references: [ $seq, $pos, $tm ]
#
my ($last_params, @last_probes);

sub get_boundary_probes {
    my ($seq, $lower_cover, $upper_cover, $len) = @_;
    my $params = "@_";
    return @last_probes if $params eq $last_params;
    my $seq_len = length($seq);
    my @probes;
    for (my $pos = 0; $pos <= $seq_len - $len; $pos++) {
	my $probe = substr($seq, $pos, $len);
	next if ! ($probe =~ /[a-z]{$lower_cover,}/);
	next if ! ($probe =~ /[A-Z]{$upper_cover,}/);
	my $tm = get_tm($probe);
	push(@probes, [ $probe, $pos, $tm ]);
    }
    $last_params = $params;
    $last_probes = @probes;
    return @probes;
}

#
#   Return next probe.  Use for long sequences to save memory.
#
sub get_next_probe {
    my ($seq, $lower_cover, $upper_cover, $len, $last_pos) = @_;
    my $seq_len = length($seq);
    my @probes;
    for (my $pos = $last_pos; $pos <= $seq_len - $len; $pos++) {
        my $probe = substr($seq, $pos, $len);
        next if ! ($probe =~ /[a-z]{$lower_cover,}/);
        next if ! ($probe =~ /[A-Z]{$upper_cover,}/);
        return [ $probe, $pos ];
    }
    return undef;
}   

#
#   Pick first probe, then rest of probes, as long as
#   probes are spaced at least $spacing apart.
#
sub tile_probes {
    my ($lines_ref, $spacing, $pos_col_num) = @_;
    my ($last_pos, @good_lines);
    for my $row (@${lines_ref}) {
	my @row = @$row;
	my $pos = $row[$pos_col_num - 1];
	if ($last_pos eq '' or ($pos - $last_pos) >= $spacing) {
	    push(@good_lines, $row);
	    $last_pos = $pos;
	}
    }
    return @good_lines;
}

#
#   Trim probes by keeping only $probes_per_seq.
#   Probes spaced evenly by index, not by position.
#
sub trim_probes {
    my ($probes_per_seq, @good_probes) = @_;
    return () if $probes_per_seq < 1;
    return @good_probes if scalar(@good_probes) <= $probes_per_seq;
    my @probes;
    my $spacing = scalar(@good_probes) / $probes_per_seq;
    my $start = $spacing / 2;
    return @good_probes if $spacing <= 1;
    for (my $i = $start; $i <= $#good_probes; $i += $spacing) {
        push(@probes, $good_probes[$i + .05]);
    }
    return @probes;
}

#
#   Trim probes by keeping only $min <= x <= $max.
#   Probes spaced evenly by index, not by position.
#
sub trim_probes_random {
    my ($min, $max, @good_probes) = @_;
    my $probes_per_seq = int(rand ($max - $min + 1) + $min);
    return trim_probes($probes_per_seq, @good_probes);
}


#
#   Put magnets at equal intervals, return list of closest probes.
#
#   Each probe in list is "pos<tab>rest of line".
#
sub magnetize_probes {
    my ($spacing, $lines_ref) = @_;

    my @list = sort { $a <=> $b; } @$lines_ref;
    my $first_pos = $list[0] + 0;
    $first_pos -= ($first_pos % $spacing);
    my $last_pos = $list[-1] + $spacing - 1;

    my @keep;
    for (my $pos = $first_pos; $pos <= $last_pos; $pos += $spacing) {
	my $ind = binary_search(\@list, $pos - $spacing);
	$ind = 0 if $ind < 0;
	$ind = $#list if $ind < $#list;
	my ($best, $best_dist);
	for (; $ind <= $#list; $ind++) {
	    my $cur = $list[$ind];
	    next if $cur < $pos - $spacing;
	    last if $cur > $pos + $spacing;
	    my $dist = abs($cur - $pos);
	    if (!$best or $dist < $best_dist) {
		$best = $cur;
		$best_dist = $dist;
	    }
	}
	next if ! $best;
	my ($p, $row) = split / /, $best; # strip position
	push(@keep, $row);
    }
    @keep = hash_unique(@keep);
    return \@keep;
}


#
#   Check for common problems.
#
#   Sets $total_probes, $N, $rep8, and $self.
#
sub good_probe {
    my ($probe) = @_;
    $total_probes++;
    if ($probe =~ /N/i) {
        $N++;
        warn "N\t$probe\n" if $debug >= 2;
        return 0;
    }
    if ($probe =~ /AAAAAAAA|TTTTTTTT|CCCCCCCC|GGGGGGGG|GTGTGTGT|CACACACA/i) {
        $rep8++;
        warn "REP8\t$probe\n" if $debug >= 2;
        return 0;
    }
    if (self_anneal(10, $probe)) {
        $self++;
        warn "SELF10\t$probe\n" if $debug >= 2;
        return 0;
    }
    return 1;
}

#
#   exon string format: start:len,start:len
#
sub get_splicing_sites {
    my ($exons) = @_;
    my @exons = split /,/, $exons;
    my @sites;
    for my $i (0 .. $#exons - 1) {
	my ($a, $b) = split /:/, $exons[$i];
	my ($c, $d) = split /:/, $exons[$i + 1];
	my $site = sprintf "%d/%d", $a + $b - 1, $c;
	push(@sites, $site);
    }
    return join(",", @sites);
}


#
#   map_probe(probe_offset, @contigs)
#
#   returns (pos, contig index, contig start, contig len)
#
sub map_probe {
    my ($probe_offset, @contigs) = @_;
    my $pos;
    for (my $i = 0; $i <= $#contigs; $i++) {
	my $contig = $contigs[$i];
	my ($s, $l) = split /:/, $contig;
	if ($l <= $probe_offset) {
	    $probe_offset -= $l;
	    $pos = $s + $probe_offset;
	}
	else {
	    $pos = $s + $probe_offset;
	    return ($pos, $i, $s, $l);
	}
    }
    die "can't map probe: probe_offset $probe_offset contigs @contigs\n";
}

sub map_probe_contigs {
    my ($offset1, $offset2, @contigs) = @_;
    my (@result, @indexes);
    my ($pos1, $c1, $start1, $len1) = map_probe($offset1, @contigs);
    my ($pos2, $c2, $start2, $len2) = map_probe($offset2, @contigs);
    my $rest1 = $len1 - ($pos1 - $start1);
    $" = ' ';
    if ($c1 == $c2) {
	my $len = $pos2 - $pos1 + 1;
	push(@result, "$pos1:$len");
	push(@indexes, $c1);
	return (\@result, "@indexes");
    }
    push(@result, "$pos1:$rest1");
    push(@indexes, $c1);
    for my $i ($c1 + 1 .. $c2 - 1) {
	push(@result, $contigs[$i]);
	push(@indexes, $i);
    }
    my $first2 = ($pos2 - $start2) + 1;
    push(@result, "$start2:$first2");
    push(@indexes, $c2);
    return (\@result, join(",", @indexes));
}


1;
