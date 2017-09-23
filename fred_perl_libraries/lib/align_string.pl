require 'sequences.pl';

sub compute_alignment_string {
    my ($ref_seq, $query_seq) = @_;
    my ($rlen, $qlen) = (length($ref_seq), length($query_seq));
    $ref_seq =~ s/-/ /g;
    $query_seq =~ s/-/ /g;
    my $str;
    for my $i (0 .. $rlen - 1) {
        my $r = substr($ref_seq, $i, 1);
        my $q = substr($query_seq, $i, 1);
        die "huh?" if $r eq ' ' and $q eq ' ';
	if ($r ne ' ' and $q ne ' ') {
	    $str .= ("\U$r" eq "\U$q") ? "M" : "m";
	}
	elsif ($r eq ' ') {                 # reference gap (reference deletion)
	    $str .= "i";
	}
	elsif ($q eq ' ') {                 # query gap (reference insertion)
	    $str .= " ";
	}
	else {
	    die "huh?";
	}
    }
    return $str;
}

sub compute_match_string {
    my $match_string;
    my $last = length($_[0]) - 1;
    for my $i (0 .. $last) {
        my $a = uc(substr($_[0], $i, 1));
        my $b = uc(substr($_[1], $i, 1));
        $match_string .= ($a eq $b) ? '|' : ' ';
    }
    return $match_string;
}

sub compress_align_string {
    my ($str) = @_;
    my $result = '';
    while ($str =~ /(M+|m+|i+| +)/g) {
	my $run = $1;
	if (length($run) == 1) {
	    $result .= $run;
	}
	else {
	    $result .= length($run) . substr($run, 0, 1);
	}
    }
    return $result;
}

sub decompress_align_string {
    my ($str) = @_;
    my $result = '';
    while ($str =~ /(\d+)?(M|m|i| )/g) {
	my $len = $1 || 1;
	$result .= $2 x $len;
    }
    return $result;
}

#
#   $caf->{rstrand} and $caf->{qstrand} are usually not set.
#   $caf->{strand} is the relative orientation of the strands.
#
sub caf2verbose_alignment {
    my ($caf, $rev) = @_;
    my $str;
    my $max_len = 60;

    my ($rstart, $qstart, $rdir, $qdir);
    if ($caf->{rstrand} eq '-') {
	$rdir = -1;
    }
    else {
	$rdir = 1;
    }
    if ($caf->{qstrand} eq '-') {
	$qdir = -1;
    }
    elsif ($caf->{qstrand} eq '+') {
	$qdir = 1;
    }
    elsif ($caf->{strand} eq '-') {
	$qdir = - $rdir;
    }
    else {
	$qdir = $rdir;
    }
    my $top_seq = $caf->{alignment_strings}[0];
    my $bot_seq = $caf->{alignment_strings}[1];
    my $mid_seq = $caf->{match_string};
    if ($rev) {
	$rdir *= -1;
	$qdir *= -1;
	$top_seq = rc($top_seq); # ZZZ FIX - doesn't work for proteins
	$bot_seq = rc($bot_seq);
	$mid_seq = reverse $mid_seq;
    }
    $rstart = ($rdir == 1) ? $caf->{rstart} : $caf->{rend};
    $qstart = ($qdir == 1) ? $caf->{qstart} : $caf->{qend};

    $str .= sprintf "%s $rdir %d-%d vs %s $qdir %d-%d:\n",
	    $caf->{rname}, $caf->{rstart}, $caf->{rend},
	    $caf->{qname}, $caf->{qstart}, $caf->{qend};
    my $match = $caf->{match_string};
    for (my $i = 0; $i < length($match); $i += $max_len) {
	my $top = substr($top_seq, $i, $max_len);
	my $bot = substr($bot_seq, $i, $max_len);
	my $mid = substr($mid_seq, $i, $max_len);
	my $top_used = grep(/[^-]/, split //, $top);
	my $bot_used = grep(/[^-]/, split //, $bot);
	my $rend = $rstart + ($top_used - 1) * $rdir;
	my $qend = $qstart + ($bot_used - 1) * $qdir;
	$str .= "\n";
	$str .= sprintf "%7d %s %-3d\n", $rstart, $top, $rend;
	$str .= sprintf "        %s\n", $mid;
	$str .= sprintf "%7d %s %-3d\n", $qstart, $bot, $qend;
	$rstart += $top_used * $rdir;
	$qstart += $bot_used * $qdir;
    }
    $str .= sprintf("\n       ident: %.2f, cover: %.2f, score: %.2f\n",
	$caf->{ident}, $caf->{cover}, $caf->{score});
    return $str;
}

1;
