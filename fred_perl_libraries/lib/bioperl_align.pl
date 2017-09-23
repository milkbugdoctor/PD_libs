#!/usr/bin/env activeperl-5.8

# use UNIVERSAL::dump; # implicit 'dump'

require 'align_string.pl';

use Bio::Tools::dpAlign;
use Bio::SeqIO;
use Bio::SimpleAlign;
use Bio::AlignIO;
use Bio::Matrix::IO;

use Bio::Tools::pSW;
use Bio::Ext::Align;

use Bio::Align::ProteinStatistics;

#	see bioperl-align-example for example usage
#
#	type can be: local, global, endsfree, or pSW (local)
#
#	$opts{-alphabet} can be 'protein' or 'dna'
#
sub bioperl_align {
    my ($type, $gap_open, $gap_extend, $seq1, $seq2, %opts) = @_;
    my $factory;
    $opts{-gap} = $gap_open;
    $opts{-ext} = $gap_extend;

    $opts{-alphabet} = 'protein' if $opts{-alphabet} eq '';
    $seq1 = Bio::PrimarySeq->new(-seq => $seq1, -id  => 'seq1',
	-alphabet => $opts{-alphabet});
    $seq2 = Bio::PrimarySeq->new(-seq => $seq2, -id  => 'seq2',
	-alphabet => $opts{-alphabet});
    $opts{-alphabet} = 'protein';

    if ($type eq 'pSW') {
	$opts{-matrix} = '/usr/local/install/scoring_matrices/blosum62.bla';
	$factory = new Bio::Tools::pSW(%opts);
    }
    else {
	if ($type eq 'local') {
	    $type = Bio::Tools::dpAlign::DPALIGN_LOCAL_MILLER_MYERS;
	}
	elsif ($type eq 'global') {
	    $type = Bio::Tools::dpAlign::DPALIGN_GLOBAL_MILLER_MYERS;
	}
	elsif ($type eq 'endsfree') {
	    $type = Bio::Tools::dpAlign::DPALIGN_ENDSFREE_MILLER_MYERS;
	}
	else {
	    die "unknown type '$type'";
	}
	$factory = new Bio::Tools::dpAlign(-alg => $type, %opts);
    }

    # actually do the alignment
    my $out;
    eval {
	$out = $factory->pairwise_alignment($seq1, $seq2);
    };
    # $out->dump;  # ZZZ
    if ($opts{-alphabet} eq 'dna') {
	my $rev = $seq2->revcom();
	$rev_out = $factory->pairwise_alignment($seq1, $rev);
	$out = $rev_out if $rev_out->percentage_identity > $out->percentage_identity;
    }
    return $out;
}

sub bioperl2caf {
    my ($align, $seq1, $seq2, $do_trim) = @_;
    my $caf;
    my ($align1, $align2) = ($align->each_seq());
    $caf->{rstrand} = $caf->{qstrand} = $caf->{strand} = '+'; # ZZZ FIX
    $caf->{rstart} = $align1->start;
    $caf->{qstart} = $align2->start;
    $caf->{rend} = $align1->end;
    $caf->{qend} = $align2->end;
    my $match = $align->match_line();
    my $m_len = length($match);
    my $m_start = 0;
    my $m_end = length($match) - 1;
    if ($do_trim) {
	# do trimming of ends
	while (substr($match, $m_start, 1) eq ' ') {
	    my $top = substr($align1->seq, $m_start, 1);
	    my $bot = substr($align2->seq, $m_start, 1);
	    last if $top ne '-' && $bot ne '-';
	    $caf->{rstart}++ if $top ne '-';
	    $caf->{qstart}++ if $bot ne '-';
	    $m_start++;
	    $m_len--;
	}
	while (substr($match, $m_end, 1) eq ' ') {
	    my $top = substr($align1->seq, $m_end, 1);
	    my $bot = substr($align2->seq, $m_end, 1);
	    last if $top ne '-' && $bot ne '-';
	    $caf->{rend}-- if $top ne '-';
	    $caf->{qend}-- if $bot ne '-';
	    $m_end--;
	    $m_len--;
	}
    }
    my $m_len = $m_end - $m_start + 1;
    $top_seq = substr($align1->seq, $m_start, $m_len);
    $bot_seq = substr($align2->seq, $m_start, $m_len);
    my $align_str = compute_alignment_string($top_seq, $bot_seq);
    $caf->{match_string} = compute_match_string($top_seq, $bot_seq);
    $caf->{rgap} = $align_str =~ tr/i/i/;
    $caf->{qgap} = $align_str =~ tr/ / /;
    $caf->{tgap} = $caf->{rgap} + $caf->{qgap};
    my $matches = $align_str =~ tr/M/M/;
    $caf->{align} = $align_str;
    $caf->{alignment_strings} = [ $top_seq, $bot_seq ];
    $caf->{rsize} = length($seq1);
    $caf->{rname} = 'seq1'; # ZZZ FIX
    $caf->{rlen} = $caf->{rend} - $caf->{rstart} + 1;
    $caf->{qsize} = length($seq2);
    $caf->{qname} = 'seq2'; # ZZZ FIX
    $caf->{qlen} = $caf->{qend} - $caf->{qstart} + 1;
    $caf->{ident} = 100 * $matches / $m_len;
    $caf->{match} = $matches;
    $caf->{cover} = $caf->{qlen} / $caf->{qsize} * 100;
    $caf->{rcover} = $caf->{rlen} / $caf->{rsize} * 100;
    $caf->{score} = $caf->{ident} * $caf->{cover} / 100;
    $caf->{rscore} = $caf->{ident} * $caf->{rcover} / 100;
    return $caf;
}

1;
