
sub get_delta_score {
    my ($hit_str, $read_size) = @_;
    my ($first, @deltas) = split /\n/, $hit_str;
    my ($ts, $te, $rs, $re, $mis, @other) = split /\s+/, $first;
    my $tlen = abs($te - $ts) + 1;
    my $rlen = abs($re - $rs) + 1;
    my ($tgap, $rgap) = (0, 0);
    for my $d (@deltas) {
	if ($d > 0) {
	    $rgap++;
	}
	elsif ($d < 0) {
	    $tgap++;
	}
    }
    $mis = $mis - $rgap - $tgap;
    my $match = $rlen - $mis - $tgap;
    die "$mis is negative" if $mis < 0;
# warn "ident = ($match * 2 - $mis - 2 * $rgap - 2 * $tgap) / ($read_size * 2) * 100;\n";
    my $ident = ($match * 2 - $mis - 2 * $rgap - 2 * $tgap) / ($read_size * 2) * 100;
# warn "got ident $ident for $hit_str\n";
    return $ident;
}

#
#   Fred's "Common Alignment Format" to Delta.
#   Depends on "~/bin/perl/lib/psl.pm".
#
sub caf2delta {
    my ($r) = @_;
    my $deltas;
    my $mismatches = 0;
    my $last_pos = 0;
    my $pos = 0;
    for my $c (split //, decompress_align_string($r->{align})) {
	$pos++;
        if ($c eq 'i') {                # reference gap (query insertion)
            $deltas .= sprintf "%d\n", -($pos - $last_pos);
            $last_pos = $pos;
            $mismatches++;
        }
        elsif ($c eq ' ') {             # query gap (reference insertion)
            $deltas .= sprintf "%d\n", ($pos - $last_pos);
            $last_pos = $pos;
            $mismatches++;
        }
        elsif ($c eq 'm') {
            $mismatches++;
        }
    }
    my $result;
    if ($r->{block_num} == 1) {
	$result .= sprintf ">%s %s %d %d\n", $r->{rname}, $r->{qname}, $r->{rsize}, $r->{qsize};
    }
    $result .= sprintf "%d %d ", $r->{rstart}, $r->{rend};
    my $strand = $r->{strand};
    if ($strand eq '+') {
	$result .= sprintf "%d %d ", $r->{qstart}, $r->{qend};
    }
    else {
	$result .= sprintf "%d %d ", $r->{qend}, $r->{qstart};
    }
    $result .= sprintf "%d %d %d\n", $mismatches, $mismatches, 0;
    $result .= $deltas;
    $result .= "0\n";
    return $result;
}

#
#   Fred's old \"aligns\" format to Delta.
#   Depends on "~/bin/perl/lib/psl.pm".
#
sub aligns2delta {
    my ($r) = @_;
    my $deltas;
    my $mismatches = 0;
    my $last_pos = 0;
    my $pos = 0;
    for my $c (split //, decompress_align_string($r->{align})) {
	$pos++;
        if ($c eq 'i') {                # reference gap (query insertion)
            $deltas .= sprintf "%d\n", -($pos - $last_pos);
            $last_pos = $pos;
            $mismatches++;
        }
        elsif ($c eq ' ') {             # query gap (reference insertion)
            $deltas .= sprintf "%d\n", ($pos - $last_pos);
            $last_pos = $pos;
            $mismatches++;
        }
        elsif ($c eq 'm') {
            $mismatches++;
        }
    }
    my $result;
    if ($r->{block_num} == 1) {
	$result .= sprintf ">%s %s %d %d\n", $r->{tname}, $r->{qname}, $r->{tsize}, $r->{qsize};
    }
    $result .= sprintf "%d %d ", $r->{tstart}, $r->{tend};
    my $strand = $r->{qstrand} || $r->{strand};
    if ($strand eq '+') {
	$result .= sprintf "%d %d ", $r->{qstart}, $r->{qend};
    }
    else {
	$result .= sprintf "%d %d ", $r->{qend}, $r->{qstart};
    }
    $result .= sprintf "%d %d %d\n", $mismatches, $mismatches, 0;
    $result .= $deltas;
    $result .= "0\n";
    return $result;
}

1;
