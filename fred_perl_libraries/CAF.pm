
require 'align_string.pl';

package CAF;	# Common Alignment Format

sub rlen {
    my $caf = shift;
    return $caf->{rlen} if defined $caf->{rlen};
    if (defined $caf->{rstart} && defined $caf->{rend}) {
	return $caf->{rlen} = $caf->{rend} - $caf->{rstart} + 1;
    }
    die "cannot compute {rlen} because {rstart} or {rend} is undefined";
}

sub qlen {
    my $caf = shift;
    return $caf->{qlen} if defined $caf->{qlen};
    if (defined $caf->{qstart} && defined $caf->{qend}) {
	return $caf->{qlen} = $caf->{qend} - $caf->{qstart} + 1;
    }
    die "cannot compute {qlen} because {qstart} or {qend} is undefined";
}

sub decompressed_align {
    my $caf = shift;
    die "{align} is undefined" if ! defined $caf->{align};
    if ($caf->{align} !~ /\d/) {
	return $caf->{align};
    }
    else {
	return decompress_align_string($caf->{align});
    }
}

sub compressed_align {
    my $caf = shift;
    die "{align} is undefined" if ! defined $caf->{align};
    if ($caf->{align} !~ /\d/) {
	return compress_align_string($caf->{align});
    }
    else {
	return $caf->{align};
    }
}

#
#   Recompute fields based on:
#	align, qstart, qend, qsize, rstart, rend, and rsize.
#
sub recompute {
    my $caf = shift;
    my $align_str = decompressed_align($caf);
    my $m_len = length($align_str);
    $caf->{rgap}   = $align_str =~ tr/i/i/;
    $caf->{qgap}   = $align_str =~ tr/ / /;
    $caf->{tgap}   = $align_str =~ tr/i /i /;
    my $matches    = $align_str =~ tr/M/M/;
    my $mismatches = $align_str =~ tr/m/m/;
    $caf->{rlen}   = $caf->{rend} - $caf->{rstart} + 1;
    $caf->{qlen}   = $caf->{qend} - $caf->{qstart} + 1;
    $caf->{ident}  = 100 * $matches / $m_len;
    $caf->{match}  = $matches;
    $caf->{mism}   = $mismatches;
    $caf->{mis}    = $mismatches + $caf->{rgap} + $caf->{qgap};
    $caf->{cover}  = $caf->{qlen} / $caf->{qsize} * 100;
    $caf->{rcover} = $caf->{rlen} / $caf->{rsize} * 100;
    $caf->{score}  = $caf->{ident} * $caf->{cover} / 100;
    $caf->{rscore} = $caf->{ident} * $caf->{rcover} / 100;
}

sub round {
    my $caf = shift;
    for my $i (qw/ident cover score rcover rscore bscore/) {
	if (defined $caf->{$i}) {
	    my $tmp = sprintf("%.3f", $caf->{$i});
	    $tmp =~ s/\.0+$//;
	    $caf->{$i} = $tmp;
	}
    }
}

1;
