
require 'sestoft_align.pl';

sub sestoft2caf {
    my ($hash, $seq1, $seq2, $trim) = @_;
    my $caf;
    my ($align1, $align2) = ($hash->{xalign}, $hash->{yalign});
    $caf->{rstart} = $hash->{xmin};
    $caf->{qstart} = $hash->{ymin};
    $caf->{rend} = $hash->{xmax};
    $caf->{qend} = $hash->{ymax};
    my $match = compute_alignment_string($align1, $align2);
    my $m_len = length($match);
    my $m_start = 0;
    if ($trim) {
	while (substr($match, $m_start, 1) =~ /[ i]/) {
	    $caf->{rstart}++ if substr($align1, $m_start, 1) ne '-';
	    $caf->{qstart}++ if substr($align2, $m_start, 1) ne '-';
	    $m_start++;
	}
	my $m_end = length($match) - 1;
	while (substr($match, $m_end, 1) =~ /[ i]/) {
	    $caf->{rend}-- if substr($align1, $m_end, 1) ne '-';
	    $caf->{qend}-- if substr($align2, $m_end, 1) ne '-';
	    $m_end--;
	}
	my $m_len = $m_end - $m_start + 1;
	$align1 = substr($align1, $m_start, $m_len);
	$align2 = substr($align2, $m_start, $m_len);
	($hash->{xalign}, $hash->{yalign}) = ($align1, $align2);
	$match = substr($match, $m_start, $m_end - $m_start + 1);
    }
    $caf->{align} = $match;
    my $matches = $match =~ tr/M/M/;
    $caf->{rgap} = $match =~ tr/i/i/;
    $caf->{qgap} = $match =~ tr/ / /;
    $caf->{tgap} = $caf->{rgap} + $caf->{qgap};
    $caf->{alignment_strings} = [ $align1, $align2 ];
    $caf->{match_string} = compute_match_string($align1, $align2);
    $caf->{rsize} = length($seq1);
    $caf->{rname} = 'seq1';
    $caf->{rlen} = $caf->{rend} - $caf->{rstart} + 1;
    $caf->{qsize} = length($seq2);
    $caf->{qname} = 'seq2';
    $caf->{qlen} = $caf->{qend} - $caf->{qstart} + 1;
    $caf->{ident} = 100 * $matches / $m_len;
    $caf->{match} = $matches;
    $caf->{cover} = $caf->{qlen} / $caf->{qsize} * 100;
    $caf->{rcover} = $caf->{rlen} / $caf->{rsize} * 100;
    $caf->{score} = $caf->{ident} * $caf->{cover} / 100;
    $caf->{rscore} = $caf->{ident} * $caf->{rcover} / 100;
    if (0) {
	for my $key (sort keys %$caf) {
	    print "    $key:\t$caf->{$key}\n";
	}
    }
    return $caf;
}

1;
