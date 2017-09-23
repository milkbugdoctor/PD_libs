require 'misc.pl';

package blat;
#
#	e.g, $match = "30 60%c" = 30bp, 60% contiguous
#		c	contiguous
#		%	percent of qsize
#		%t	% of tsize
#		%b	% of best: percent of max(qsize, tsize)
#
sub filter_psl_line {
    my ($line, $match, $verbose) = @_;
    return undef if ($line !~ /^(\d+)/);
    my ($bp, $contig, $contig_percent);
    my @row = split /\t/, $line;
    my $qsize = $row[10];
    my $tsize = $row[14];
    my $perc_size = $qsize;
    $perc_size = $tsize if $match =~ /t/;
    $perc_size = ::min($qsize, $tsize) if $match =~ /b/;
    for my $m (split /\s+/, $match) {
	if ($match =~ /c/i) {
	    $contig = $m + 0;
	    if ($m =~ /%/) { $contig = $perc_size * $m / 100; }
	}
	else {
	    if ($m =~ /%/) { $bp = $perc_size * $m / 100; }
	    else           { $bp = $m + 0; }
	}
    }
    return undef if $row[0] < $bp;

    $row[21] = $row[21];	# create if doesn't exist
    $row[22] = $row[22];	# create if doesn't exist
    my $yes = 0;
    if ($contig) {
	my @q_blocks = split /,/, $row[21];
	my @db_blocks = split /,/, $row[22];
	die "can't use contig option with no contigs" if ! @q_blocks or ! @db_blocks;
	$yes = 0;
	for my $b (0 .. $#q_blocks) {
	    my $count = 0;
	    my $q = $q_blocks[$b];
	    my $db = $db_blocks[$b];
	    my $len = length($q);
	    for my $i (1 .. $len) {
		my $a = substr($q, $i - 1, 1);
		my $b = substr($db, $i - 1, 1);
		if ("\U$a" eq "\U$b") {
		    if (++$count >= $contig) {
			$yes = 1;
			last;
		    }
		}
	    }
	    last if $count >= $contig;
	}
    }
    else {
	$yes = 1;
    }

    if ($yes) {
	return $line if $verbose;
	my $str = sprintf "$row[0]/$row[10] in $row[13] at %d-$row[16]\n", $row[15] + 1;
	return $str;
    }
    return undef;
}

sub print_new_psl_header {
    my ($out_handle, $psl_type) = @_;
    print $out_handle join("\t", qw{match mismatch repmatch N's qgapcount
	qgapbases tgapcount tgapbases strand qname qsize qstart qend
	tname tsize tstart tend blockcount blocksizes qstarts tstarts
	qseqs tseqs}), "\n";
}

sub filter_psl_results {
    my ($in_fh, $match, $out_fh) = @_;
    my $need_header = 1;
    while (<$in_fh>) {
	if ($need_header) {
	    print_new_psl_header($out_fh);
	    $need_header = 0;
	}
        my $line = filter_psl_line($_, $match, 1);
	print $out_fh $line if $line ne '';
    }
}

1;
