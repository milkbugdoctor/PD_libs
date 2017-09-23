
my $db = $gp_db || "gp_hg17";	# override with global $gp_db

my %track_table;
$track_table{'kg'}        = [ 'transcript', "$db.knownGene" ];
$track_table{'kg1'}       = [ 'transcript', "$db.kgOld" ];
$track_table{'ens'}       = [ 'transcript', "$db.ensGene" ];
$track_table{'ref'}       = [ 'transcript', "$db.refFlat" ];
$track_table{'mrna'}      = [ 'align', "$db.all_mrna" ];
$track_table{'est'}       = [ 'align', "$db.all_est", "$db.%s_est" ];
$track_table{'u133'}      = [ 'align', "$db.affyU133" ];
$track_table{'u95'}       = [ 'align', "$db.affyU95" ];
$track_table{'u133plus2'} = [ 'align', "$db.affyU133Plus2" ];
$track_table{'uni'}       = [ 'uni', "$db.uniGene_2" ];
$track_table{'mi'}        = [ 'mi', "$db.wgRna" ];
$track_table{'chromInfo'} = "$db.chromInfo";
# aliases
$track_table{'EST'}       = $track_table{'est'};	# alias
$track_table{'mRNA'}      = $track_table{'mrna'};	# alias
$track_table{'u133p2'}    = $track_table{'u133plus2'};	# alias
$track_table{'u133+2'}    = $track_table{'u133plus2'};	# alias
$track_table{'oldkg'}     = $track_table{'kg1'};	# alias
$track_table{'kgold'}     = $track_table{'kg1'};	# alias
$track_table{'kg2'}       = $track_table{'kg'};		# alias

my %track_cols;
$track_cols{transcript} = "name, chrom, strand, exonStarts, exonEnds, txStart, txEnd";
$track_cols{uni}        = "name, chrom, strand, chromStarts, blockSizes, chromStart, chromEnd";
$track_cols{align}      = "qName, tName, strand, tStarts, blockSizes, tStart, tEnd";
$track_cols{mi}         = "distinct name, chrom, strand, chromStart, chromEnd, type";

my %chr_col;
$chr_col{transcript} = "chrom";
$chr_col{uni}        = "chrom";
$chr_col{align}      = "tName";
$chr_col{mi}         = "chrom";

require 'mysql.pl';

my %id;

#   get_gp_track_header(trackname)
#
#   trackname = kg (Known Genes) - "id name chr strand start end len exons introns"
#		ens (Ensembl)
#		mrna (Human mRNA)
#		uni (UniGene)
#		ref (RefSeq)
#		u133 (Affy U133)
#		u133plus2 (Affy U133Plus2)
#		mi (miRNA)
#
sub get_gp_track_header {
    my ($track) = @_;

    my $header;
    if ($track =~ /^(uni|mrna|u133|u95|kg|ens|est|ref)/i) {
	$header = "id name chr strand start end len exons introns";
    }
    elsif ($track =~ /^mi/i) {
	$header = "id name chr strand start end len exons introns type";
    }
    else {
	die "unknown track '$track'";
    }
    return split /\s+/, $header;
}


#   get_gp_track(trackname)
#
#   trackname = kg (Known Genes) - "id name chr strand start end len exons introns"
#		ens (Ensembl)
#		mrna (Human mRNA)
#		uni (UniGene)
#		ref (RefSeq)
#		u133 (Affy U133)
#		u133plus2 (Affy U133Plus2)
#		mi (miRNA)
#
#   Return array of "id name chr strand start end len [other]"
#
sub get_gp_track {
    my ($track, $chr) = @_;

    if ($track =~ /^(uni|u133|mrna|est|kg|ens|ref|mi)/i) {
	my $reader = gp_reader::new($track, $chr);
	my $item;
	my @result;
	while (($item = $reader->get_next()) ne '') {
	    push(@result, $item);
	}
	return @result;
    }
    else {
	die "unknown track '$track'";
    }
}

#   get_known_genes()
#
#   Return array of "id name chr strand start end len exons introns"
#
sub get_known_genes {
    return get_gp_track("kg");
}


sub get_chr_lengths {
    my $fd = mysql_output("select chrom, size from $track_table{'chromInfo'}");
    my %result;
    while (<$fd>) {
	chomp;
	my ($chr, $size) = split /\t/;
	$result{$chr} = $size;
    }
    return %result;
}

package gp_reader;

sub new {
    my ($track, $chr) = @_;
    my $self = {};
    bless $self;
    my ($table_type, $table, $where_extra) = get_table($track, $chr);
    $self->{chr} = $chr;
    $self->{fd} = ::mysql_output("select $track_cols{$table_type} $extra from $table $where_extra");
    $self->{track} = $track;
    $self->{table_type} = $table_type;
    return $self;
}

sub get_table {
    my ($track, $chr) = @_;
    my $table = $track_table{lc($track)};
    die "can't find \$track_table{$table}" if ! defined $table;
    my ($table_type, $all_table, $chr_table) = @{$table};
    if ($chr ne '' && $chr_table ne '') {
	return ($table_type, sprintf("$chr_table", $chr), '');
    }
    else {
	my $chr_col = $chr_col{$table_type};
	if ($chr ne '') {
	    $chr = "where $chr_col = '$chr'";
	}
	else {
	    # $chr = "order by $chr_col";
	}
	return ($table_type, $all_table, $chr);
    }
}

sub get_next {
    my $self = shift;
    my $fd = $self->{fd};
    my @extra = @{$self->{extra}};
    my $track = $self->{track};
    if ($_ = <$fd>) {
	chomp;
	my $id = "$track." . ++$id{$track};
	if ($self->{table_type} eq 'transcript') {
	    my ($name, $chr, $strand, $exonStarts, $exonEnds, $s, $e, @extra) = split /\t/;
	    my $len = $e - $s;
	    $s++;
	    my (@exons, @introns);
	    @starts = split(/,/, $exonStarts);
	    @ends = split(/,/, $exonEnds);
	    for (my $i = 0; $i <= $#starts; $i++) {
		my $start = $starts[$i] + 1;
		my $end = $ends[$i];
		my $len = $end - $start + 1;
		push(@exons, "$start:$len");
	    }
	    shift(@starts);
	    pop(@ends);
	    for (my $i = 0; $i <= $#ends; $i++) {
		my $start = $ends[$i] + 1;
		my $end = $starts[$i];
		my $len = $end - $start + 1;
		push(@introns, "$start:$len");
	    }
	    my $exons = join(',', @exons);
	    my $introns = join(',', @introns);
	    my $res = join("\t", $id, $name, $chr, $strand, $s, $e, $len,
		    $exons, $introns, @extra);
	    return $res;
	}
	elsif ($self->{table_type} =~ /^(align)$/) {
	    my ($name, $chr, $strand, $exonStarts, $exonSizes, $s, $e, @extra) = split /\t/;
	    if ($track =~ /^(u133|u95)/i) {	# FIX ZZZ
		$name =~ s/;$//;
		$name =~ s/^.*://;
	    }
	    my $len = $e - $s;
	    $s++;
	    my (@exons, @introns, @ends);
	    my @starts = split(/,/, $exonStarts);
	    my @sizes = split(/,/, $exonSizes);
	    for (my $i = 0; $i <= $#starts; $i++) {
		my $start = $starts[$i] + 1;
		my $end = $starts[$i] + $sizes[$i];
		die "start $s > exon start $start" if $s > $start;
		die "end $e < exon end $end" if $e < $end;
		my $len = $sizes[$i];
		push(@exons, "$start:$len");
	    }
	    shift(@starts);
	    pop(@ends);
	    for (my $i = 0; $i <= $#ends; $i++) {
		my $start = $s + $ends[$i];
		my $end = $s + $starts[$i] - 1;
		my $len = $end - $start + 1;
		push(@introns, "$start:$len");
	    }
	    my $exons = join(',', @exons);
	    my $introns = join(',', @introns);
	    return join("\t", $id, $name, $chr, $strand, $s, $e, $len,
		    $exons, $introns);
	}
	elsif ($self->{table_type} =~ /^(uni)$/) {
	    my ($name, $chr, $strand, $exonStarts, $exonSizes, $s, $e, @extra) = split /\t/;
	    my $len = $e - $s;
	    $s++;
	    my (@exons, @introns, @ends);
	    my @starts = split(/,/, $exonStarts);
	    my @sizes = split(/,/, $exonSizes);
	    for (my $i = 0; $i <= $#starts; $i++) {
		my $start = $s + $starts[$i];
		my $len = $sizes[$i];
		my $end = $starts + $len - 1;
		die "start $s > exon start $start" if $s > $start;
		die "end $e < exon end $end" if $e < $end;
		push(@exons, "$start:$len");
	    }
	    shift(@starts);
	    pop(@ends);
	    for (my $i = 0; $i <= $#ends; $i++) {
		my $start = $s + $ends[$i];
		my $end = $s + $starts[$i] - 1;
		my $len = $end - $start + 1;
		push(@introns, "$start:$len");
	    }
	    my $exons = join(',', @exons);
	    my $introns = join(',', @introns);
	    return join("\t", $id, $name, $chr, $strand, $s, $e, $len,
		    $exons, $introns);
	}
	elsif ($self->{table_type} eq 'mi') {
	    #
	    #   Return array of "id name chr strand start end len exons introns type"
	    #
	    my ($name, $chr, $strand, $s, $e, $type) = split /\t/;
	    my $len = $e - $s; $s++;
	    return join("\t", $id, $name, $chr, $strand, $s, $e, $len, "$s:$len", "", $type);
	}
	else {
	    die "huh?";
	}
    }
    return undef;
}

1;
