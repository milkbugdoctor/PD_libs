
use Bio::Tools::CodonTable;
use Bio::SeqUtils;
use Bio::Perl;

my $myCodonTable = Bio::Tools::CodonTable->new();
my %codon_tables;

my @aa = Bio::SeqUtils->valid_aa;
my %X_hash;
for my $aa (@aa) {
    if ($aa =~ /[A-Z]/) {
	for my $codon ($myCodonTable->revtranslate($aa)) {
	    $X_hash{$codon} = 1;
	}
    }
}

require 'misc.pl';
require 'primers.pl';

sub ambiguity {
    my $observed = $_[0];
    $observed =~ tr/acgt/ACGT/;
    $observed =~ s/\///g;
    $observed = join('', sort &unique(split(//, $observed)));
    return "A" if $observed eq "A";
    return "C" if $observed eq "C";
    return "G" if $observed eq "G";
    return "T" if $observed eq "T";
    return "M" if $observed eq "AC";
    return "H" if $observed eq "ACT";
    return "W" if $observed eq "AT";
    return "Y" if $observed eq "CT";
    return "V" if $observed eq "ACG";
    return "R" if $observed eq "AG";
    return "S" if $observed eq "CG";
    return "K" if $observed eq "GT";
    return "N" if $observed eq "ACGT";
    return "D" if $observed eq "AGT";
    return "B" if $observed eq "CGT";
    # warn "What is '$observed'? in &ambiguity($_[0])";
    return "?";
}

sub degenerate_to_regex {
    my $oligo = $_[0];
    my $result;
    $observed =~ tr/a-z/A-Z/;
    for (my $i = 0; $i < length($oligo); $i++) {
	my $char = substr($oligo, $i, 1);
	if ($char =~ /[ACGT]/i) {
	    $result .= $char;
	}
	elsif ($char =~ /[MHWYVRSKNDB]/i) {
	    my $set;
	    if ($char eq "M")    { $set = "[AC]" }
	    elsif ($char eq "H") { $set = "[ACT]" }
	    elsif ($char eq "W") { $set = "[AT]" }
	    elsif ($char eq "Y") { $set = "[CT]" }
	    elsif ($char eq "V") { $set = "[ACG]" }
	    elsif ($char eq "R") { $set = "[AG]" }
	    elsif ($char eq "S") { $set = "[CG]" }
	    elsif ($char eq "K") { $set = "[GT]" }
	    elsif ($char eq "N") { $set = "[ACGT]" }
	    elsif ($char eq "D") { $set = "[AGT]" }
	    elsif ($char eq "B") { $set = "[CGT]" }
	    $result .= $set;
	}
	else {
	    die "unknown nucleotide '$char'";
	}
    }
    return $result;
}

sub disambiguate {
    my $oligo = $_[0];
    my @result = ('');
    $observed =~ tr/a-z/A-Z/;
    for (my $i = 0; $i < length($oligo); $i++) {
	my $char = substr($oligo, $i, 1);
	my $next;
	if ($char =~ /[ACGT]/i) {
	    for my $res (@result) {
		$res .= $char;
	    }
	}
	elsif ($char =~ /[MHWYVRSKNDB]/i) {
	    if ($char eq "M") { $next = "AC" }
	    elsif ($char eq "H") { $next = "ACT" }
	    elsif ($char eq "W") { $next = "AT" }
	    elsif ($char eq "Y") { $next = "CT" }
	    elsif ($char eq "V") { $next = "ACG" }
	    elsif ($char eq "R") { $next = "AG" }
	    elsif ($char eq "S") { $next = "CG" }
	    elsif ($char eq "K") { $next = "GT" }
	    elsif ($char eq "N") { $next = "ACGT" }
	    elsif ($char eq "D") { $next = "AGT" }
	    elsif ($char eq "B") { $next = "CGT" }
	    my @new_result;
	    for my $res (@result) {
		for my $code (split(//, $next)) {
		    push(@new_result, $res . $code);
		}
	    }
	    @result = @new_result;
	}
	else {
	    die "unknown nucleotide '$char'";
	}
    }
    return @result;
}

#
#   FIX: maybe we should use the BioPerl verison
#
sub valid_aa_codes {
    return "ACDEFGHIKLMNPQRSTVWY";
}

#
#   amino acid to nucleotide
#
sub amino_to_nuc {
    my @codons;
    die "only single peptide allowed" if length($_[0]) != 1;
    return keys %X_hash if $_[0] =~ /^X$/i;
    my @codons = $myCodonTable->revtranslate("\U$_[0]");
    return @codons if wantarray;
    my $codons = join(" ", @codons);
    return "\U$codons";
}

#
#   nuc_to_amino(dna_string, codon_table)
#
sub nuc_to_amino {
    if (defined $_[1]) {
	my $table = $codon_tables{$_[1]};
	if (! defined $table) {
	    $table = $codon_tables{$_[1]} = Bio::Tools::CodonTable->new(-id => $_[1]);
	}
	return $table->translate($_[0]);
    }
    else {
	return translate_as_string($_[0]);
    }
}

sub prot_to_degenerate {
    my $result;
    for my $amino (split //, $_[0]) {
	my $res;
	my $triplets = amino_to_nuc($amino);
	my @triplets = split / /, $triplets;
	my %hash;
	for my $trip (@triplets) {
	    for (my $i = 0; $i < length($trip); $i++) {
		$hash{$i} .= substr($trip, $i, 1);
	    }
	}
	for my $key (keys %hash) {
	    my $nuc = &ambiguity($hash{$key});
	    $nuc = "\L$nuc" if ! ($nuc =~ /[ACGT]/);
	    substr($res, $key, 1) = $nuc;
	}
	$result .= $res;
    }
    return $result;
}

#
#   Warning: It's exponential!
#
sub prot_to_alternatives {
    my @result = ('');
    for my $amino (split //, $_[0]) {
	my $res;
	my $triplets = amino_to_nuc($amino);
	my @triplets = split / /, $triplets;
	my @new_result;
	for my $trip (@triplets) {
	    for my $alt (@result) {
		push(@new_result, $alt . $trip);
	    }
	}
	@result = @new_result;
    }
    return @result;
}

1;
