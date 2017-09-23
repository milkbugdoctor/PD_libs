#!/usr/local/bin/perl

package main;

require 'misc.pl';
require 'sequences.pl';
require 'align_string.pl';
require 'delta.pl';

package psl;

use Carp qw{confess};

sub new {
    shift if $_[0] eq 'psl';
    my $file = shift;
    my $self = {};
    bless $self;

    if (!defined($self->{fd} = ::get_file_handle($file))) {
        open($self->{fd}, $file) || confess "can't open file '$file': $!";
    }
    return $self;
}

sub get_next_line {
    my $self = shift;
    my $fd = $self->{fd};
    while (1) {
	my $line = <$fd>;
	last if ! defined $line;
	chomp($line);
	my @line = split /\t/, $line;
	next if $line[0] !~ /^\d+$/;
	my $hash = { };
	my $i = 0;
	$hash->{match} = $line[$i++];
	$hash->{mismatch} = $line[$i++];
	$hash->{repmatch} = $line[$i++];
	$hash->{ncount} = $line[$i++];
	$hash->{qgapcount} = $line[$i++];
	$hash->{qgapbases} = $line[$i++];
	$hash->{tgapcount} = $line[$i++];
	$hash->{tgapbases} = $line[$i++];
	$hash->{strand} = $line[$i++];
	$hash->{qname} = $line[$i++];
	$hash->{qsize} = $line[$i++];
	$hash->{qstart} = $line[$i++];
	$hash->{qend} = $line[$i++];
	$hash->{tname} = $line[$i++];
	$hash->{tsize} = $line[$i++];
	$hash->{tstart} = $line[$i++];
	$hash->{tend} = $line[$i++];
	$hash->{blockcount} = $line[$i++];
	$hash->{blocksizes} = $line[$i++];
	$hash->{qstarts} = $line[$i++];
	$hash->{tstarts} = $line[$i++];
	$hash->{qseqs} = $line[$i++];
	$hash->{tseqs} = $line[$i++];
	return $hash;
    }
    return undef;
}

package main;

sub roundit {
    $_[0] = round_to($_[0] * 100, .01);
}

sub psl2aligns {
    my ($r, $max_gap) = @_;
    my $qname = $r->{qname};
    my $qstarts = $r->{qstarts};
    my $tstarts = $r->{tstarts};
    my $blocksizes = $r->{blocksizes};
    my $tname = $r->{tname};
    my $qseqs = $r->{qseqs};
    my $tseqs = $r->{tseqs};
    my $qsize = $r->{qsize};
    my $tsize = $r->{tsize};
    my $strand = $r->{strand};
    if ($qseqs eq '') {
	die "\nfound empty [qseqs] column";
    }
    if ($tseqs eq '') {
	die "\nfound empty [tseqs] column";
    }
    my @tstarts = split /,/, $tstarts;
    my @qstarts = split /,/, $qstarts;
    my @blocks = split /,/, $blocksizes;
    my @qseqs = split /,/, $qseqs;
    my @tseqs = split /,/, $tseqs;
    my $block_num = 1;
    my @aligns;
    while (@tstarts) {
	my $tstart = $tstarts[0];	# pos of first block
	my $qstart = $qstarts[0];	# pos of first block
	my $last_t = $tstart;		# pos of next block
	my $last_q = $qstart;		# pos of next block
	my $align = '';
	my $i = 0;
	my $matches = 0;
	for ($i = 0; $i <= $#tstarts; $i++) {
	    my $new_tstart = $tstarts[$i];
	    my $new_qstart = $qstarts[$i];
	    my $tgap = $new_tstart - $last_t;
	    my $qgap = $new_qstart - $last_q;
	    last if $tgap > $max_gap || $qgap > $max_gap;
	    $align .= ' ' x $tgap;
	    $align .= 'i' x $qgap;
	    my $tseq = $tseqs[$i];
	    my $qseq = $qseqs[$i];
	    if (length($tseq) != length($qseq)) {
		my $tlen = length($tseq);
		my $qlen = length($qseq);
		die "huh? tlen $tlen != qlen $qlen";
	    }
	    $last_t = $new_tstart;	# pos of last block
	    $last_q = $new_qstart;	# pos of last block
	    for (my $j = 0; $j < length($tseq); $j++) {
		if (uc(substr($tseq, $j, 1)) eq uc(substr($qseq, $j, 1))) {
		    $align .= 'M';
		    # $align .= uc(substr($tseq, $j, 1)); 
		    $matches++;
		}
		else {
		    $align .= 'm';
		    # $align .= lc(substr($tseq, $j, 1)); 
		}
		$last_t++;
		$last_q++;
	    }
	}
	my $len = length($align);

	$tstart++;	# pos of first block
	$qstart++;	# pos of first block
	my $tend = $last_t;
	my $qend = $last_q;
	if ($strand eq '-') {
	    my $new_end = $qsize - $qstart + 1;
	    my $new_start = $qsize - $qend + 1;
	    $qend = $new_end;
	    $qstart = $new_start;
	}
	my $ident = $matches/$len;
	my $cov = ($qend - $qstart + 1) / $qsize;
	my $tcov = ($tend - $tstart + 1) / $tsize;
	my $score = $ident * $cov;
	my $tscore = $ident * $tcov;
	my $bscore = $ident * max($cov, $tcov);
	roundit($ident);
	roundit($cov);
	roundit($score);
	roundit($tcov);
	roundit($tscore);
	roundit($bscore);
	my $tlen = $tend - $tstart + 1;
	my $hash;

	$hash->{block_num} = $block_num;
	$hash->{strand} = $strand;

	$hash->{qname}  = $qname;
	$hash->{qstart} = $qstart;
	$hash->{qend}   = $qend;
	$hash->{qlen}   = $qend - $qstart + 1;
	$hash->{qsize}  = $qsize;

	$hash->{ident} = $ident;
	$hash->{cov}   = $cov;	# for backwards compatibility
	$hash->{cover} = $cov;
	$hash->{score} = $score;
	$hash->{matches} = $matches;
        $hash->{mism}    = $align =~ tr/m/m/;
        $hash->{rgap}    = $align =~ tr/i/i/;
        $hash->{qgap}    = $align =~ tr/ / /;
        $hash->{tgap}    = $align =~ tr/i /i /;
        $hash->{mis}     = $align =~ tr/i m/i m/;

	# for psl2caf
	$hash->{rname} = $tname;
	$hash->{rstart} = $tstart;
	$hash->{rend} = $tend;
	$hash->{rlen} = $tend - $tstart + 1;
	$hash->{rsize} = $tsize;
	$hash->{rcov} = $tcov;
	$hash->{rcover} = $tcov;
	$hash->{rscore} = $tscore;
	$hash->{match} = $matches;

	# for psl2aligns
	$hash->{tname} = $tname;
	$hash->{tstart} = $tstart;
	$hash->{tend} = $tend;
	$hash->{tlen} = $tend - $tstart + 1;
	$hash->{tsize} = $tsize;
	$hash->{tcov} = $tcov;
	$hash->{tcover} = $tcov;
	$hash->{tscore} = $tscore;

	$hash->{bscore} = $bscore;
	$hash->{align} = compress_align_string($align);
	push(@aligns, $hash);

	splice(@blocks, 0, $i);
	splice(@tstarts, 0, $i);
	splice(@qstarts, 0, $i);
	splice(@tseqs, 0, $i);
	splice(@qseqs, 0, $i);
	$block_num++;
    }
    return @aligns;
}

sub psl2caf {
    return psl2aligns(@_);
}

sub psl2delta {
    my ($r, $max_gap) = @_;
    my @aligns = psl2caf($r, $max_gap);
    my $result;
    for my $hash (@aligns) {
	$result .= caf2delta($hash);
    }
    return $result;
}

1;

__END__

# sample program

package main;

my $psl = new psl 'infile.psl';
while (my $hash = $psl->get_next_line()) {
    my @hash = %$hash;
    print "got @hash\n";
}


