
require 'misc.pl';
require 'ranges.pl';

package Delta;

use Carp qw{cluck confess};
use IO::Handle;

#
#   Delta::new($file) = $file can be filename or handle
#
sub new {
    shift if $_[0] eq 'Delta';
    my ($file) = @_;
    my $self = {};
    bless $self;
    my $fd;
    if (!($fd = ::get_file_handle($file))) {
        open($fd, $file) || confess "can't open file '$file': $!";
    }
    my $header = $self->{header} = $fd->getline();
    my ($ref, $query) = split /\s+/, $header;
    $self->{ref} = $ref;
    $self->{query} = $query;
    $self->{fd} = $fd;
    my $nucmer = $fd->getline;
    $self->{header} .= $nucmer;
    confess "expected NUCMER line" if $nucmer !~ /^NUCMER/;
    $self->{hash} = { };
    return $self;
}

# ZZZ FIX - maybe we should use our Fasta module here?

#
#   get positions for sequences in FASTA file
#
sub get_file_positions {
    my ($self, $which, $load_seqs) = @_;
    my ($pos, $cached);
    if ($load_seqs) {
	$cached = $self->{$which, "cached"} = $self->{$which, "cached"} || { };
    }
    else {
	$pos = $self->{$which, "positions"};
	return $pos if defined $pos;
	$pos = $self->{$which, "positions"} = { };
    }
    my $fd;
    open($fd, $self->{$which}) or confess "$self->{$which}: $!";
    my ($key, $first_pos, $last_pos, $seq);
    while (1) {
	$_ = <$fd>;
	if ($_ eq '' || /^>/) {
	    if (defined $key) {
		if (!$load_seqs) {
		    my $len = ($last_pos - $first_pos);
		    $pos->{$key} = "$first_pos $len";
		}
		else {
		    $seq =~ s/\s//g;
		    $cached->{$key} = $seq;
		}
	    }
	    last if $_ eq '';
	    s/^>//;
	    s/\s.*//s;
	    $key = $_;
	    $first_pos = tell $fd;
	    $last_pos = tell $fd;
	    $seq = '';
	}
	else {
	    $last_pos = tell $fd;
	    $seq .= $_;
	}
    }
    if (!$load_seqs) {
	$self->{$which, "fd"} = new IO::Handle;
	open($self->{$which, "fd"}, $self->{$which}) or confess "$self->{$which}: $!";
	return $pos;
    }
}

sub load_sequences {
    get_file_positions($_[0], 'ref', 1);
    get_file_positions($_[0], 'query', 1);
}

#
#   So that we don't have to keep redundant copies of headers
#
sub store_string {
    my ($self, $what, $string) = @_;
    my $hash = $self->{hash};
    my $id;
    $id = $hash->{$what}{$string};
    return $id if ($id = $hash->{$what}{$string}) ne '';
    $id = @{$hash->{"$what-array"}} + 0;
    $hash->{$what}{$string} = $id;
    $hash->{"$what-array"}[$id] = \$string;
    return $id;
}

sub get_entry {
    my $self = shift;
    my $entry;
    my $fd = $self->{fd};
    if (($_ = <$fd>) ne '') {
	if (/^>/) {
	    $self->{last_header} = $_;
	    $_ = <$fd>;
	}
	$self->{last_header} =~ /^>(\S+)\s+(\S+)\s+(\d+)\s+(\d+)/;
	my ($ref, $query, $ref_size, $query_size) = ($1, $2, $3, $4);
	$entry->{ref} = store_string($self, 'ref', "$ref $ref_size");
	$entry->{query} = store_string($self, 'query', "$query $query_size");
	$entry->{align} = $_;
	$entry->{gaps} = '';

	while ((my $c = $fd->getc) ne '') {
	    last if $c eq '';
	    $fd->ungetc(ord($c));
	    last if $c eq '>';
	    my $line = $fd->getline;
	    last if $line =~ /^0$/;
	    $entry->{gaps} .= $line;
	}
    }
    if (defined $entry) {
	$entry->{delta} = $self;
	bless $entry, "Entry";
    }
    return $entry;
}


sub Delta::sum_scores {
    my ($scores, $missed) = @_;
    my $score = 0;
    for my $i (0 .. $#{$scores}) {
	$score += $scores->[$i] + $missed->[$i];
    }
    return $score;
}


#
#   Delta::combined_scores($entry1, $entry2)
#
sub combined_scores {
    my (@entry, @scores, @missed, @start, @end, @rstart, @rend, @align);
    for my $i (0 .. $#_) {
	$entry[$i] = $_[$i];
	($scores[$i], $missed[$i]) = $entry[$i]->get_alignment_scores();
	($start[$i], $end[$i], $qstrand[$i], $rstrand[$i])
	    = ($entry[$i]->get_align())[2, 3];
	($rstart[$i], $rend[$i]) = $entry[$i]->get_ref_positions();
    }
    die "huh?" if @entry != 2;
    die "huh?" if $entry[0]->{ref} ne $entry[1]->{ref};
    die "huh?" if $entry[0]->{query} ne $entry[1]->{query};
    my $overlap_start = ::max($start[0], $start[1]);
    my $overlap_end = ::min($end[0], $end[1]);
    my $start = ::min($start[0], $start[1]);
    my $end = ::max($end[0], $end[1]);
    my ($mismatch, $ref_gap_open, $ref_gap_extend, $query_gap_open)
	= $entry[0]->{delta}->get_penalties();
    my $overlap = ($overlap_start <= $overlap_end) ? 1 : 0;
    my @combined_scores = ([], []);
    my @combined_missed = ([], []);
    my (@segments, $combined_rstart, $combined_rend);
    my ($best, $best_score);
    my $first_seq = ($start[0] < $start[1]) ? 0 : ($start[1] < $start[0]) ? 1 : undef;
    my $last_seq = ($end[0] > $end[1]) ? 0 : ($end[1] > $end[0]) ? 1 : undef;
    for my $prefer (0, 1) {			# which overlapping portion to use
	last if $prefer == 1 and ! $overlap;
	my ($rstart, $rend, $ref_gap, $in_ref_gap);
	my $c_scores = $combined_scores[$prefer];
	my $c_missed = $combined_missed[$prefer];
	for my $i ($start .. $end) {
	    if ($i < $overlap_start) {
		my $j = $first_seq;
		if ($start[$j] <= $i && $i <= $end[$j]) {
		    push(@$c_scores, $scores[$j]->[$i - $start[$j]]);
		    push(@$c_missed, $missed[$j]->[$i - $start[$j]]);
		    $rstart = $rstart[$j] if $i == $start;
		}
		else {
		    $ref_gap++;
		    if ($in_ref_gap) { push(@$c_scores, -abs($ref_gap_extend)); }
		    else             { push(@$c_scores, -abs($ref_gap_open)); }
		    $in_ref_gap = 1;
		    push(@$c_missed, 0);
		}
	    }
	    # overlap, no ref gap:
	    elsif ($i >= $overlap_start && $i <= $overlap_end) {
		push(@$c_scores, $scores[$prefer]->[$i - $start[$prefer]]);
		if ($i == $overlap_start && defined($first_seq) && $prefer != $first_seq) {
		    push(@$c_missed, -abs($query_gap_open));
		}
		else {
		    push(@$c_missed, $missed[$prefer]->[$i - $start[$prefer]]);
		}
		$rend = $rend[$prefer];
	    }
	    elsif ($i > $overlap_end) {
		my $missed;
		if ($ref_gap) {
		    $missed = -abs($ref_gap_open) - (($ref_gap - 1) * abs($ref_gap_extend));
		    $ref_gap = 0;
		}
		elsif ($overlap && $prefer != $last_seq && $i == $overlap_end + 1) {
		    $missed = -abs($query_gap_open);
		}
		my $hit;
		my $j = $last_seq;
		if ($start[$j] <= $i && $i <= $end[$j]) {
		    push(@$c_scores, $scores[$j]->[$i - $start[$j]]);
		    if (defined $missed) {
			push(@$c_missed, $missed);
		    }
		    else {
			push(@$c_missed, $missed[$j]->[$i - $start[$j]]);
		    }
		    $rend = $rend[$j];
		}
		else {
		    die "huh? hit gap in last sequence!";
		}
	    }
	    else {
		die "huh?";
	    }
	}
	my $this_score = sum_scores($c_scores, $c_missed);
	if (! defined $best_score or $this_score > $best_score) {
	    $best_score = $this_score;
	    $best = $prefer;
	    $combined_rstart = $rstart;
	    $combined_rend = $rend;
	}
    }
    if ($overlap) {
	if (defined $first_seq) {
	    push(@{$segments[$first_seq]}, $start[$first_seq], $overlap_start - 1);
	}
	push(@{$segments[$best]}, $overlap_start, $overlap_end);
	if (defined $last_seq) {
	    push(@{$segments[$last_seq]}, $overlap_end + 1, $end[$last_seq]);
	}
	::range_merge(0, $segments[0]);
	::range_merge(0, $segments[1]);
    }
    else {
	@{$segments[0]} = ($start[0], $end[0]);
	@{$segments[1]} = ($start[1], $end[1]);
    }

    my $combined_entry = { };
    bless $combined_entry, "Entry";
    $combined_entry->{delta} = $entry[0]->{delta};
    $combined_entry->{ref} = $entry[0]->{ref};
    $combined_entry->{query} = $entry[0]->{query};
    $combined_entry->{align} = join(" ", $combined_rstart, $combined_rend, $start, $end) . "\n";
    $combined_entry->{scores} = $combined_scores[$best];
    $combined_entry->{missed} = $combined_missed[$best];
    $combined_entry->{entries} = [ @entry ];
    $combined_entry->{segments} = [ @segments ];
    return ($best_score, $combined_entry);
}

sub set_penalties {
    my $self = shift;
    die "need 4 penalties" if @_ != 4;
    $self->{penalties} = [ @_ ];
}

sub get_penalties {
    my $self = shift;
    die "no penalties defined" if ! defined $self->{penalties};
    return @{$self->{penalties}};
}

if (0) {
    my $foo = Delta::new($ARGV[0]);
    while (my $entry = $foo->get_entry) {
	my @stats = $entry->get_align_stats();
	printf "got entry scores @stats\n";
    }
}

##############################################################################
#
#	Entry:
#		align
#		gaps
#		query, ref - used to get header from Delta
#		scores, missed - refs to arrays of base scores
#
##############################################################################

package Entry;

use Carp qw{cluck confess};
use IO::Handle;

sub get_text {
    my $entry = shift;
    my @header = $entry->get_header();
    my $text = ">" . join(" ", @header[0, 2, 1, 3]) . "\n";
    $text .= $entry->{align};
    $text .= $entry->{gaps};
    $text .= "0\n";
    return $text;
}

sub print {
    my $entry = shift;
    my ($fd) = @_;
    my $text = $entry->get_text();
    print $fd $text;
}

#
#   Make copy of entry for chaining
#
sub copy {
    my ($entry) = @_;
    my $new = { };
    %$new = %$entry;
    bless $new, "Entry";
    $new->{scores} = [ @{$entry->{scores}} ] if defined $entry->{scores};
    $new->{missed} = [ @{$entry->{missed}} ] if defined $entry->{missed};
    return $new;
}

#
#   Returns ($ref_name, $ref_size, $query_name, $query_size).
#
sub get_header {
    my $entry = shift;
    my $self = $entry->{delta};
    my @ref = keys %{$self->{hash}};
    my $ref = ${$self->{hash}{"ref-array"}[$entry->{ref}]};
    my $query = ${$self->{hash}{"query-array"}[$entry->{query}]};
    return split /\s+/, "$ref $query";
}

#
#   Get the reference positions corresponding to start and end of query
#
sub get_ref_positions {
    my ($entry) = @_;
    my $self = $entry->{delta};
    my ($rs, $re, $qs, $qe) = split /\s+/, $entry->{align};
    my $rstrand = ($rs <= $re) ? "+" : "-";
    my $qstrand = ($qs <= $qe) ? "+" : "-";
    if ($rstrand eq $qstrand) {
	return ($rs, $re);
    }
    else {
	return ($re, $rs);
    }
}

#
#   Returns (ref_start, ref_end, query_start, query_end,
#		ref_strand, query_strand, mismatches)
#
#   ref_start <= ref_end and query_start <= query_end
#
sub get_align {
    my ($entry) = @_;
    my $self = $entry->{delta};
    my ($rs, $re, $qs, $qe, $mis, @other) = split /\s+/, $entry->{align};
    my $rstrand = ($rs <= $re) ? "+" : "-";
    my $qstrand = ($qs <= $qe) ? "+" : "-";
    ($rs, $re) = ($re, $rs) if $rstrand eq '-';
    ($qs, $qe) = ($qe, $qs) if $qstrand eq '-';
    return ($rs, $re, $qs, $qe, $rstrand, $qstrand, $mis);
}

#
#   Expand alignments, return gapped sequences.
#
sub get_aligned_seqs {
    my ($entry, $query_order) = @_;
    my $delta = $entry->{delta};
    my $ref_seq = $entry->get_align_seq('ref');
    my $query_seq = $entry->get_align_seq('query');
    die "gaps undefined" if ! defined $entry->{gaps};
    my @deltas = split /\n/, $entry->{gaps};
    my $pos = 0;
    for my $d (@deltas) {
	if ($d > 0) { # +num : advance num and insert 1 empty base in query
	    substr($query_seq, $pos + $d - 1, 0) = ' ';
	    $pos += $d;
	}
	else {
	    substr($ref_seq, $pos - $d - 1, 0) = ' ';
	    $pos += -$d;
	}
    }
    my $rlen = length($ref_seq);
    my $qlen = length($query_seq);
    die "rlen $rlen != qlen $qlen" if $rlen != $qlen;
    return ($ref_seq, $query_seq) if ! $query_order;
    return (rc($ref_seq), rc($query_seq));
}


#
#   Split entry and return new entry.
#
sub cut {
    my ($entry, $start, $end) = @_;
warn "\ncutting entry @_\n"; # ZZZ
    confess "bad start/end" if $start eq '' or $end eq '';

    my ($ref_start, $ref_end, $query_start, $query_end) = split /\s+/, $entry->{align};
    if ($start == $query_start and $end == $query_end) {
	return $entry->copy();
    }

    my ($ref_seq, $query_seq) = $entry->get_aligned_seqs();
# warn "    rs $ref_start re $ref_end qs $query_start qe $query_end\n"; # ZZZ
# printf STDERR "    qaligned %d\n", length($query_seq); #ZZZ
    my @base_extent;
    if ($query_start <= $query_end) {
	@base_extent = (1 + $start - $query_start, 1 + $end - $query_start);	# FIX?
    }
    else {
	($start, $end) = ($end, $start);
	@base_extent = (1 + $query_start - $start, 1 + $query_start - $end);	# FIX?
    }
# warn "    extent @base_extent\n"; # ZZZ

    my ($ref_bases, $query_bases, $first, $last, $ref_first, $ref_last);
    for my $pos (1 .. length($query_seq)) {
	$ref_bases++ if substr($ref_seq, $pos, 1) ne ' ';
	$query_bases++ if substr($query_seq, $pos, 1) ne ' ';
	$first = $pos if ($query_bases == $base_extent[0]);
	$last = $pos if ($query_bases == $base_extent[1]);
	$ref_first = $ref_bases if ($query_bases == $base_extent[0]);
	$ref_last = $ref_bases if ($query_bases == $base_extent[1]);
    }
    die "huh? first = '$first', last = '$last', query_bases $query_bases, base_extent @base_extent" if $first eq '' or $last eq '';

    my $new_entry = $entry->copy();

    my @deltas;
    my $mismatches = 0;
    my $last_pos = $first - 1;
    for my $pos ($first .. $last) {
	my $r = substr($ref_seq, $pos - 1, 1);
	my $q = substr($query_seq, $pos - 1, 1);
	confess "huh?" if $r eq ' ' and $q eq ' ';
	if ($r eq ' ') {		# reference gap (reference deletion)
	    push(@deltas, -($pos - $last_pos));
	    $last_pos = $pos;
	    $mismatches++;
	}
	elsif ($q eq ' ') {		# query gap (reference insertion)
	    push(@deltas, $pos - $last_pos);
	    $last_pos = $pos;
	    $mismatches++;
	}
	elsif ($q ne $r) {
	    $mismatches++;
	}
    }

# warn "new deltas @deltas\n"; # ZZZ
    $new_entry->{gaps} = join("\n", @deltas) . "\n";

    $new_entry->{align} = join(" ", $ref_start + $ref_first - 1, $ref_start + $ref_last - 1, $start, $end,
	$mismatches, $mismatches, 0) . "\n";
# warn "new align $new_entry->{align}\n";

    delete $new_entry->{scores};
    delete $new_entry->{missed};

    return $new_entry;
}

#
#   Return the subsequence used in the actual alignment.
#   Reference sequence is always left to right, query might be reversed.
#
sub get_align_seq {
    my ($entry, $what) = @_;
    my ($rs, $re, $qs, $qe, $rstrand, $qstrand, $mis) = $entry->get_align();
    my $seq = $entry->get_whole_seq_ref($what);
    if ($what eq 'ref') {
	# reference is always oriented left to right
	return substr($$seq, $rs - 1, $re - $rs + 1);
    }
    else {
	my $sub = substr($$seq, $qs - 1, $qe - $qs + 1);
	# fix sequence orientation
	return ($rstrand eq $qstrand) ? $sub : rc($sub);
    }
}

#
#   Return the whole sequence related to the alignment.
#
sub get_whole_seq_ref {
    my ($entry, $what) = @_;
    my $delta = $entry->{delta};
    my ($ref_name, $ref_size, $query_name, $query_size) = $entry->get_header();
    my $key = ($what eq 'ref') ? $ref_name : $query_name;
    my $cached = $delta->{$what, "cached"};
    return \$cached->{$key} if defined $cached->{$key};
    my $pos = $delta->get_file_positions($what) or confess "can't find positions for '$what'";
    defined $pos->{$key} or confess "can't find positions for '$key' in '$what'";
    my ($offset, $len) = split /\s+/, $pos->{$key};
    my $fd = $delta->{$what, "fd"};
    my $filename = $delta->{$what};
    seek($fd, $offset, 0) || confess "can't seek to $offset in '$filename'";
    my $data;
    read($fd, $data, $len) || confess "can't read $len bytes from '$filename'";
    $data =~ s/\s//g;
    $data = "\U$data"; # convert to upper case
    $delta->{$what, "cached"}->{$key} = $data;
    return \$data;
}

sub rc {
    my ($seq) = @_;
    $seq =~ tr/ACGTacgt/TGCAtgca/;
    $seq = scalar reverse $seq;
    return $seq;
}

#
#   Get plus or minus score for each query position
#
#   $entry->get_alignment_scores()
#
sub get_alignment_scores {
    my ($entry) = @_;
    my $cached_scores = $entry->{scores};
    my $cached_missed = $entry->{missed};
    return ($cached_scores, $cached_missed) if defined $cached_scores;
    my ($mismatch, $ref_gap_open, $ref_gap_extend, $query_gap_open)
	= $entry->{delta}->get_penalties($entry->{delta});
    my ($ref_seq, $query_seq) = $entry->get_aligned_seqs(1);
    my ($rlen, $qlen) = (length($ref_seq), length($query_seq));
    die "rlen $rlen != qlen $qlen" if $rlen != $qlen;
    my $len = length($ref_seq);
    my (@scores, @missed);
    my ($in_ref_gap, $in_query_gap);
    my $missed = 0;
    for my $i (0 .. $len - 1) {
	my $r = substr($ref_seq, $i, 1);
	my $q = substr($query_seq, $i, 1);
	die "huh?" if $r eq ' ' and $q eq ' ';
	if ("\U$r" eq "\U$q") {
	    push(@scores, 1);
	    push(@missed, $missed);
	    $missed = 0;
	    $in_ref_gap = $in_query_gap = 0;
	}
	elsif ($r ne ' ' and $q ne ' ') {	# simple mismatch
	    push(@scores, -abs($mismatch));
	    push(@missed, $missed);
	    $missed = 0;
	    $in_ref_gap = $in_query_gap = 0;
	}
	elsif ($r eq ' ') {			# reference gap (reference deletion)
	    if ($in_ref_gap) {
		push(@scores, -abs($ref_gap_extend));
	    }
	    else {
		push(@scores, -abs($ref_gap_open));
	    }
	    $in_ref_gap = 1;
	    push(@missed, $missed);
	    $missed = 0;
	}
	elsif ($q eq ' ') {			# query gap (reference insertion)
	    if (!$in_query_gap) {
		$missed -= abs($query_gap_open);
	    }
	    $in_query_gap = 1;
	}
	else {
	    die "huh?";
	}
    }
# print "$ref_seq\n$query_seq\n@scores\n@missed\n\n";
    $entry->{scores} = [ @scores ];
    $entry->{missed} = [ @missed ];
    return (\@scores, \@missed);
}


#
#   Get max trimmed size
#
sub get_max_trim {
    my ($entry) = @_;
    my ($ref_name, $ref_size, $query_name, $query_size) = $entry->get_header();
    my ($rs, $re, $qs, $qe) = $entry->get_align();
    my $max_gap = ::max($qs - 1, $query_size - $qe);
    return $max_gap;
}

#
#   Get max gap in query or reference
#
sub get_max_gap {
    my ($entry) = @_;
    my $first = $entry->{align};
    die "gaps undefined" if ! defined $entry->{gaps};
    my @deltas = split /\n/, $entry->{gaps};
    my ($tgap, $rgap) = (0, 0);
    my $max_gap = 0;
    for my $d (@deltas) {
	if ($d > 1) {
	    $rgap = 1;
	}
	elsif ($d == 1) {
	    $rgap++;
	}
	elsif ($d < -1) {
	    $tgap = 1;
	}
	elsif ($d == -1) {
	    $tgap++;
	}
	else {
	    $rgap = $tgap = 0;
	}
	$max_gap = ::max($max_gap, $rgap);
	$max_gap = ::max($max_gap, $tgap);
    }
    return $max_gap;
}

sub get_score {
    my $entry = shift;
    my @scores = $entry->get_alignment_scores();
    return Delta::sum_scores(@scores);
}

sub get_align_stats_hash {
    my ($entry) = @_;
    my %hash;
    my $first = $entry->{align};
    die "gaps undefined" if ! defined $entry->{gaps};
    my @deltas = split /\n/, $entry->{gaps};
    my ($ref, $ref_size, $query, $query_size) = $entry->get_header();
    my ($ts, $te, $rs, $re, $mis, @other) = split /\s+/, $first;
    my $tlen = abs($te - $ts) + 1;
    my $rlen = abs($re - $rs) + 1;
    my ($tgap, $rgap) = (0, 0);
    for my $d (@deltas) {
	if ($d > 0) {
	    $rgap++;	# insert space in read (query)
	}
	elsif ($d < 0) {
	    $tgap++;	# insert space in template (reference)
	}
    }
    my $align_len = $rlen + $rgap;
    confess "alignment length discrepancy" if $align_len != $tlen + $tgap;
    $mis = $mis - $rgap - $tgap;
    die "mismatches [$mis] is negative" if $mis < 0;
    my $match = $rlen - $mis - $tgap;
    $hash{mis}       = $mis;
    $hash{match}     = $match;
    $hash{ref_gap}   = $tgap;
    $hash{query_gap} = $rgap;
    $hash{ident} = $match / $align_len * 100;
    $hash{query_cover} = $hash{cover} = $rlen / $query_size * 100;
    $hash{query_score} = $hash{score} = $hash{ident} * $hash{cover} / 100;
    $hash{ref_cover} = $tlen / $ref_size * 100;
    $hash{ref_score} = $hash{ident} * $hash{ref_cover} / 100;
    return \%hash;
}

sub get_align_stats {
    my ($entry) = @_;
    my $first = $entry->{align};
    die "gaps undefined" if ! defined $entry->{gaps};
    my @deltas = split /\n/, $entry->{gaps};
    my ($ref, $ref_size, $query, $query_size) = $entry->get_header();
    my ($ts, $te, $qs, $qe, $mis, @other) = split /\s+/, $first;
    my $tlen = abs($te - $ts) + 1;
    my $qlen = abs($qe - $qs) + 1;
    my ($tgap, $rgap) = (0, 0);
    for my $d (@deltas) {
	if ($d > 0) {
	    $rgap++;	# insert space in read (query)
	}
	elsif ($d < 0) {
	    $tgap++;	# insert space in template (reference)
	}
    }
    my $align_len = $qlen + $rgap;
    # sanity check
    if ($align_len != $tlen + $tgap) {
	confess "alignment length discrepancy:\n" .
	"qlen $qlen + rgap $rgap != tlen $tlen + tgap $tgap\n" .
	"for $ref vs $query\n";
    }

    $mis = $mis - $rgap - $tgap;
    my $match = $qlen - $mis - $tgap;
# warn "mis $mis match $match\n";
    die "mismatches [$mis] is negative" if $mis < 0;
    my $ident = $match / $align_len * 100;
    my $cover = $qlen / $query_size * 100;
    my $score = $ident * $cover / 100;
    return ($ident, $rgap, $tgap, $align_len, $score, $cover);
}

#
#   Return the trimmed flanks from the query sequence,
#   oriented relative to the reference.
#
sub get_trimmed_seqs {
    my ($entry, $query_order, $max_bases) = @_;
    my ($rs, $re, $qs, $qe, $rstrand, $qstrand, $mis) = $entry->get_align();
    my $seq = $entry->get_whole_seq_ref('query');
    my $left = substr($$seq, 0, $qs - 1);
    $left = substr($left, -$max_bases);
    my $right = substr($$seq, $qe);
    $right = substr($right, 0, $max_bases);
    # fix sequence orientation
    return ($rstrand eq $qstrand || $query_order) ? ($left, $right) : (rc($right), rc($left));
}

#
#   Get coded alignment string in reference order.
#   Space represents query gap, lowercase represents reference gap.
#
#   If $real_bases > 0 then use encoded real bases, and add missing flanks.
#
sub get_alignment_string {
    my ($entry, $real_bases) = @_;
    my ($ref_seq, $query_seq) = $entry->get_aligned_seqs(0);
    my ($rlen, $qlen) = (length($ref_seq), length($query_seq));
    my $str;
    for my $i (0 .. $rlen - 1) {
	my $r = substr($ref_seq, $i, 1);
	my $q = substr($query_seq, $i, 1);
	die "huh?" if $r eq ' ' and $q eq ' ';
	if ($real_bases) {
	    if ($r ne ' ' and $q ne ' ') {
		$str .= ("\U$r" eq "\U$q") ? "\U$q" : "\L$q";
	    }
	    elsif ($r eq ' ') {			# reference gap (reference deletion)
		$q =~ tr/ACGTNacgtn/1234512345/ == 1 or die "bad base '$q'";
		$str .= $q;
	    }
	    elsif ($q eq ' ') {			# query gap (reference insertion)
		$str .= " ";
	    }
	    else {
		die "huh?";
	    }
	}
	else {
	    if ($r ne ' ' and $q ne ' ') {
		$str .= ("\U$r" eq "\U$q") ? "M" : "m";
	    }
	    elsif ($r eq ' ') {			# reference gap (reference deletion)
		$str .= "i";
	    }
	    elsif ($q eq ' ') {			# query gap (reference insertion)
		$str .= " ";
	    }
	    else {
		die "huh?";
	    }
	}
    }
    return $str;
}

1;
