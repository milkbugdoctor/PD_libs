
require 'align_string.pl';

# use Fasta;
require 'sestoft2caf.pl';
require 'sestoft_align.pl';
require 'bioperl_align.pl';
require 'misc.pl';
require 'fasta.pl';	# for print_wrapped()
require 'translate.pl';	# translate DNA to protein

package Genes;

# my $matrix = ::create_simple_matrix(3, -3, "ATCG"); # for sestoft

use strict;
use Round;

#
#   Add rseq column to a CAF entry
#
sub add_rseq_column {
    my ($row, $fasta) = @_;
    if ($row->{rseq} eq '') {
        $row->{rseq} = $fasta->get_strand_seq($row->{rname},
	    $row->{qstrand}, $row->{rstart}, $row->{rend});
    }
}

#
#   Add qseq column to a CAF entry
#
#   Assume '+' strand by default;
#
sub add_qseq_column {
    my ($row, $fasta, $strand) = @_;
    if ($row->{qseq} eq '') {
	my $strand = $strand || '+';
        $row->{qseq} = $fasta->get_strand_seq($row->{qname},
	    $strand, $row->{qstart}, $row->{qend});
    }
}

#
#   Try to fix alignments that miss alternate start codon.
#   Assumes {rseq} is on {qstrand} and {qseq} is on "+" strand.
#
sub fix_gene_alignment {
    my ($row, $rfasta, $qfasta) = @_;
    my $max_gap = 9; # allow 3 codons
    for my $what (qw/start end/) {
	my ($codon_gap, $fix_what);
	if ($what eq 'start') {
	    $codon_gap = $row->{qstart} - 1;
	    $fix_what = ($row->{qstrand} eq '+') ? 'start' : 'end';
	}
	elsif ($what eq 'end') {
	    $codon_gap = $row->{qsize} - $row->{qend};
	    $fix_what = ($row->{qstrand} eq '+') ? 'end' : 'start';
	}
	else {
	    die "huh?";
	}
	next if $codon_gap < 1 || $codon_gap > $max_gap;
	my ($start, $end) = ($row->{rstart}, $row->{rend});
	# fix rseq
	if ($fix_what eq 'start') {
	    $start = $row->{rstart} - $codon_gap;
	    return if $start < 1;
	}
	else {
	    $end = $row->{rend} + $codon_gap;
	    return if $end > $row->{rsize};
	}
	my $rseq = $rfasta->get_strand_seq($row->{rname},
		$row->{qstrand}, $start, $end);
	return if $what eq 'start' && $rseq !~ /^(.TG|AT.)/i;
	return if $what eq 'end' && $rseq !~ /(TAA|TAG|TGA)$/i;
	# fix qseq
	if ($what eq 'start') {
	    $row->{qstart} = 1;
	}
	else {
	    $row->{qend} = $row->{qsize};
	}
	my $qseq = $qfasta->get_strand_seq($row->{qname},
		'+', $row->{qstart}, $row->{qend});
	$row->{qseq} = $qseq if defined $row->{qseq};
	$row->{qlen}   = $row->{qend} - $row->{qstart} + 1;

print STDERR "\nfixing $row->{qname} $what in $row->{rname} by $codon_gap\n";
printf STDERR "gene_type %s\n", $row->{gene_type};
printf STDERR "qseq: [%s %s]\n", substr($qseq, 0, $max_gap), substr($qseq, -$max_gap);
printf STDERR "rseq: [%s %s]\n", substr($rseq, 0, $max_gap), substr($rseq, -$max_gap);
printf STDERR "lens: %d %d\n", $row->{rlen}, $row->{qlen};
	$row->{rseq}   = $rseq;
	$row->{rstart} = $start;
	$row->{rend}   = $end;
	$row->{rlen}   = $end - $start + 1;

	# create alignment string for added stuff
	my $new;
	for my $i (0 .. $codon_gap - 1) {
	    my $r = uc(substr($rseq, $i, 1));
	    my $q = uc(substr($qseq, $i, 1));
	    $new .= ($r eq $q) ? 'M' : 'm';
	}

	# get the old alignment string
	my $align = ::decompress_align_string($row->{align});
	if ($row->{align} ne '') {
	    # merge with old alignment string
	    if ($row->{qstrand} eq '+') {
		$align = $new . $align;
	    }
	    else {
		$align = $align . reverse($new);
	    }
	    # and update stats
	    $row->{align} = ::compress_align_string($align);
	    $row->{match} = $align =~ tr/M/M/;
	    $row->{mism}  = $align =~ tr/m/m/;
	    $row->{rgap}  = $align =~ tr/i/i/;
	    $row->{qgap}  = $align =~ tr/ / /;
	    $row->{tgap}  = $align =~ tr/i /i /;
	    $row->{mis}   = $align =~ tr/i m/i m/;
	}
	else {
	    # bummer!  no alignment string!  just update stats then.
	    $row->{match}    += $new =~ tr/M/M/ if $row->{match} ne '';
	    $row->{mism}     += $new =~ tr/m/m/ if $row->{mism} ne '';
	    $row->{rgap}     += $new =~ tr/i/i/ if $row->{rgap} ne '';
	    $row->{qgap}     += $new =~ tr/ / / if $row->{qgap} ne '';
	    $row->{tgap}     += $new =~ tr/i /i / if $row->{tgap} ne '';
	    $row->{mis}      += $new =~ tr/i m/i m/ if $row->{mis} ne '';
	}

	# update the rest of the statistics
	$row->{cover} = $row->{qlen} / $row->{qsize} * 100;
	$row->{rcover} = $row->{rlen} / $row->{rsize} * 100;
	if ($row->{ident} ne '') {
	    my $mlen  = $row->{rlen} + $row->{rgap};
	    $mlen = length($align) if $mlen == 0;
	    my $matches = $row->{match};
	    if ($mlen > 0 && $matches > 0) {
		$row->{ident} = 100 * $matches / $mlen;
	    }
	    else {
		warn "cannot fix {ident}";
	    }
	}
	if ($row->{score} ne '') {
	    if ($row->{ident} ne '' && $row->{cover} ne '') {
		$row->{score} = $row->{ident} / 100 * $row->{cover};
	    }
	    else {
		warn "cannot fix {score} because {ident} or {cover} is unset";
	    }
	}
	if ($row->{rscore} ne '') {
	    if ($row->{ident} ne '' && $row->{rcover} ne '') {
		$row->{rscore} = $row->{ident} / 100 * $row->{rcover};
	    }
	    else {
		warn "cannot fix {rscore} because {ident} or {rcover} is unset";
	    }
	}
    }
}


#
#   ref   = genome
#   query = gene
#
#   Sets these columns:
#	shift        number of nucleotides in frame shifts
#	rflags       rseq flags
#	gene_flags   gene_seq flags
#	pseudo       flags for query/ref comparison
#	pident       protein identity
#	shifted      how many bases in ref are frame-shifted?
#
#   Codes for rflags and gene_flags:
#	s	begins with start codon
#	e	ends at stop codon (but might be out-of-frame)
#	*	stop codon is in frame (protein level)
#
#   Codes for pseudo:
#	>	first part of gene missing
#	s	have same start codons
#	S	have different start codons
#	e	have same ending stop codons
#	E	have different ending stop codons
#	<	last part of gene missing
#	r	earlier stop codon in rseq
#	g	earlier stop codon in gene_Seq
#
sub annotate_pseudo_status {
    my ($row, $genome_fasta, $reads_fasta) = @_;

    add_rseq_column($row, $genome_fasta) if $row->{rseq} eq '';
    my $rseq = uc($row->{rseq});
    $row->{rflags} = set_seq_flags($rseq);

    add_qseq_column($row, $reads_fasta) if $row->{qseq} eq '';
    my $qseq = uc($row->{qseq});
    # $row->{qflags} = set_seq_flags($qseq);

    die "gene_seq column missing" if $row->{gene_seq} eq '';

    my $gene_seq = $row->{gene_seq};
    $row->{gene_flags} = set_seq_flags($gene_seq);

    if ($row->{rflags} =~ /s/ && $row->{gene_flags} =~ /s/) {
	if (substr($rseq, 0, 3) eq substr($gene_seq, 0, 3)) {
	    $row->{pseudo} .= 's'; # has same start codon
	}
	else {
	    $row->{pseudo} .= 'S'; # has different start codon
	}
    }
    if ($row->{rflags} =~ /e/ && $row->{gene_flags} =~ /e/) {
        if (substr($rseq, -3) eq substr($gene_seq, -3)) {
            $row->{pseudo} .= 'e'; # has same stop codon
        }
        else {
            $row->{pseudo} .= 'E'; # has different stop codon
        }
    }
    # check if first part of gene is missing
    $row->{pseudo} = ">$row->{pseudo}" if $row->{qstart} > 1;
    # check if last part of gene is missing
    $row->{pseudo} .= '<' if $row->{qend} < $row->{qsize};

    #
    # get protein sequences
    #
    my $qprot = ::nuc_to_amino($gene_seq, 11); # ZZZ FIX - should we be using gene_seq??
    my $rprot = ::nuc_to_amino($rseq, 11);

    #
    # do protein alignment
    #
    my $bioperl_align = ::bioperl_align('global', 5, 2, $rprot, $qprot, -alphabet => 'protein');
    my $caf = ::bioperl2caf($bioperl_align, $rprot, $qprot);
    my ($top, $bot) = @{$caf->{alignment_strings}};
    for my $i (0 .. length($top) - 1) {
	my ($r, $q) = (substr($top, $i, 1), substr($bot, $i, 1));
	if ($q eq '*' && $r ne '*') {
	    $row->{pseudo} .= 'g'; # earlier stop codon
	    last;
	}
	if ($r eq '*' && $q ne '*') {
	    $row->{pseudo} .= 'r'; # earlier stop codon
	    last;
	}
    }

    $row->{pident} = Round::round_and_trim($caf->{ident}, 3);

printf STDERR "\nrname %s %d-%d qname %s %d-%d rflags %s gene_flags %s pseudo %s\n",
    $row->{rname}, $row->{rstart}, $row->{rend},
    $row->{qname}, $row->{qstart}, $row->{qend},
    $row->{rflags}, $row->{gene_flags}, $row->{pseudo};
printf STDERR "pident %.2f\n", $row->{pident};
printf STDERR "gene_seq: [%s %s]\n", substr($gene_seq, 0, 9), substr($gene_seq, -9);
printf STDERR "rseq: [%s %s]\n", substr($rseq, 0, 9), substr($rseq, -9);

    if ($rprot ne $qprot) {
	print STDERR "qprot $qprot\nrprot $rprot\n";
	my $tmp .= ::caf2verbose_alignment($caf);
	$tmp =~ s/^/\t/gm;
	print STDERR "$tmp\n";
    }

    #
    # find DNA frameshifts
    #
    $row->{shifted} = 0;
    if ($rseq ne $gene_seq) {
	my $bioperl_align = ::bioperl_align('local', 5, 2, $rseq, $gene_seq,
	    -alphabet => 'dna', -match => 3, -mismatch => -3);
	my $caf = ::bioperl2caf($bioperl_align, $rseq, $gene_seq);

	my ($shifted, $normal, $shift);
	my $align_str = ::decompress_align_string($caf->{align});
	for my $c (split //, $align_str) {
	    if ($c eq ' ') {
		$shift = ($shift + 1) % 3;
	    }
	    elsif ($c eq 'i') {
		$shift = ($shift - 1) % 3;
		next; # not present in ref, so don't count
	    }
	    if ($shift != 0) {
		$shifted++;
	    }
	    else {
		$normal++;
	    }
	}
	$row->{shifted} = $shifted + 0;
	if (1) { # ZZZ
	    my $tmp = sprintf "shifted: %d\n", $row->{shifted};
	    $tmp .= ::caf2verbose_alignment($caf, 1);
	    $tmp =~ s/^/\t/gm;
	    warn "$tmp\n";
	}
    }
}

sub fix_caf {
    my ($caf, $f, $s) = @_;
    $caf->{rstrand} = $f->{qstrand};
    $caf->{qstrand} = $s->{qstrand};
    my $strand = ($caf->{rstrand} eq $caf->{qstrand}) ? '+' : '-';
    $caf->{strand} = $strand;
    my $offset = -1;
    if ($caf->{rstrand} eq '+') {
	$caf->{rstart} += $offset + $f->{rstart};
	$caf->{rend} += $offset + $f->{rstart};
    }
    else {
	$caf->{rend} = $f->{rend} - $offset - $caf->{rstart};
	$caf->{rstart} = $caf->{rend} - $caf->{rlen} + 1;
    }
    if ($caf->{qstrand} eq '+') {
	$caf->{qstart} += $offset + $s->{qstart};
	$caf->{qend} += $offset + $s->{qstart};
    }
    else {
	$caf->{qend} = $s->{qend} - $offset - $caf->{qstart};
	$caf->{qstart} = $caf->{qend} - $caf->{qlen} + 1;
    }
}

sub set_seq_flags {
    my ($seq) = @_;
    my $flags;
    if (substr($seq, 0, 3) =~ /^(.TG|AT.)$/i) {
	$flags .= 's'; # has start codon
    }
    if (substr($seq, -3) =~ /^(TAA|TAG|TGA)$/i) {
	$flags .= 'e'; # has stop codon at end
    }
    #
    # find protein frameshifts
    #
    my $prot = ::nuc_to_amino($seq, 11);
    if (substr($prot, -1) eq '*') {
	$flags .= '*'; # has in-frame stop codon at the end
    }
    return $flags;
}

1;
