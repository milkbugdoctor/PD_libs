
sub rc {
    my ($seq) = @_;
    $seq =~ tr/ACGTacgt/TGCAtgca/;
    $seq = scalar reverse $seq;
    return $seq;
}

sub gc_content {
    my ($primer) = @_;
    my @primer = split('', $primer);
    my @GC = grep(/[GC]/i, @primer);
    return scalar @GC / scalar @primer;
}

sub num_matches {
    my ($seq1, $seq2) = @_;
    return 0 if $seq1 eq '' or $seq2 eq '';
    my $count = 0;
    my @a = split //, $seq1;
    my @b = split //, $seq2;
    for my $i (0 .. $#a) {
	my $a = $a[$i];
	my $b = $b[$i];
	$count++ if "\U$a" eq "\U$b";
    }
    return $count;
}

sub num_mismatches {
    my ($seq1, $seq2) = @_;
    my $count = 0;
    my @a = split //, $seq1;
    my @b = split //, $seq2;
    for my $i (0 .. $#a) {
	my $a = $a[$i];
	my $b = $b[$i];
	$count++ if "\U$a" ne "\U$b";
    }
    return $count;
}

sub add_error {
    my ($seq, $qual) = @_;
    my $len = length($seq);
    my $type = int(rand 3);
    my $pos = int(rand $len);
    my @chars = ('A', 'C', 'G', 'T');
    my $char = $chars[int(rand 4)];
    if ($type == 0) {
        substr($seq, $pos, 1) = $char;
    }
    elsif ($type == 1) {
        substr($seq, $pos, 0) = $char;
        my @qual = split /\s+/, $qual;
        splice(@qual, $pos, 0, 25);
        $qual = join(' ', @qual);
    }
    elsif ($type == 2) {
        substr($seq, $pos, 1) = ''; 
        my @qual = split /\s+/, $qual;
        splice(@qual, $pos, 1);
        $qual = join(' ', @qual);
    }
    ($_[0], $_[1]) = ($seq, $qual);
}   

sub self_anneal {
    my ($word_len, $probe) = @_;
    my $last_pos = length($probe) - 2 * $word_len;
    my $rc = rc($probe);
    my $rc_len = length($probe) - $word_len;
    for (my $pos = 0; $pos <= $last_pos; $pos++) {
	my $mer = substr($probe, $pos, $word_len);
	if (substr($rc, 0, $rc_len) =~ /$mer/i) {
	    return $pos + $word_len;	# offset past badness
	}
	$rc_len--;
    }
    return 0;
}

sub longest_tandem {
    my ($len, $seq) = @_;
    my %hash;
    my $wt_tr = 0;
    for my $i (0 .. length($seq) - $len) {
        my $pat = uc(substr($seq, $i, $len));
	my $num = $len;
	for (my $j = $i + $len; $j <= length($seq) - $len; $j += $len) {
	    my $pat2 = uc(substr($seq, $j, $len));
	    last if $pat ne $pat2;
	    $num += $len;
	}
	$wt_tr = $num if $num > $wt_tr;
    }
    return $wt_tr;
}

1;
