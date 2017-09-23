#!/usr/bin/perl
#
#	This should probably be added to golden_path.pl
#

my $debug = 0;

$gp_db = "gp_hg17" if $gp_db eq '';

require 'mysql.pl';
require 'misc.pl';
require 'markers.pl';
require 'golden_path.pl';

package refseq;

my $gp_db = $::gp_db;

use Carp;

my %markers;

my %table;
$table{'known'}     = "$gp_db.knownGene";
$table{'U133'}      = "$gp_db.knownToU133";
$table{'U133Plus2'} = "$gp_db.knownToU133Plus2";

#
#   Returns array of tab-separated values:
#       $chr, $strand, $start, $end, $name, $index, $exons, $introns, @other;
#
#   $gene_type : refseq | known
#   $type      : portion of gene to use: all | exon | intron
#   $cover     : portion of input sequence to cover: all | any
#
sub 'get_covering_genes {
    my ($gene_type, $type, $cover, $chr, $strand, $start, $end) = @_; # informative
    ::load_markers($gene_type, $type);
    return $markers{$gene_type}{$type}->get_covering_markers($cover, $chr, $strand, $start, $end);
}

sub 'get_covering_gene_indexes {
    my ($gene_type, $type, $cover, $chr, $strand, $start, $end) = @_; # informative
    ::load_markers($gene_type, $type);
    return $markers{$gene_type}{$type}->get_covering_marker_indexes($cover, $chr, $strand, $start, $end);
}

sub 'get_gene_by_index {
    my ($gene_type, $type, $index) = @_;
    return $markers{$gene_type}{$type}->get_marker($index);
}

sub 'get_covering_refseqs {
    return ::get_covering_genes('refseq', @_);
}

sub 'get_covering_known_genes {
    return ::get_covering_genes('known', @_);
}

sub 'load_markers {
    my ($gene_type, $type, $chr, @options) = @_;
    if (!defined($markers{$gene_type}{$type})) {
	$markers{$gene_type}{$type} = markers::new(@options);
	&get_genes($gene_type, $type, $markers{$gene_type}{$type}, $chr);
    }
}

sub 'unload_markers {
    my ($gene_type, $type) = @_;
    undef $markers{$gene_type}{$type};
}

sub 'get_affy {
    my ($name) = @_;
    load_affy if ! defined %affy;
    return (split /\t/, $affy{$name})[0, 1];
}

#
#   $gene_type == 'refseq' or 'known' or 'miRNA'
#   $type == 'all' or 'exon' or 'intron'
#   $markers == marker object reference
#
#   Sets
#	@gene_array
#
sub get_genes {
    my ($gene_type, $type, $markers, $chr) = @_;
    warn "get_genes($gene_type, $type)\n" if $debug;
    die "got type '$type', expected all|exon|intron" if $type !~ /^all|exon|intron$/;
    my ($reader, @gene_array);
    if ($gene_type eq 'refseq') {
        $reader = gp_reader::new('ref');
    }
    elsif ($gene_type eq 'known' || $gene_type eq 'kg') {
        $reader = gp_reader::new('kg', $chr);
    }
    elsif ($gene_type =~ /^mrna$/i) {
        $reader = gp_reader::new('mrna', $chr);
    }
    elsif ($gene_type =~ /^est$/i) {
        $reader = gp_reader::new('est', $chr);
    }
    elsif ($gene_type eq 'miRNA') {
        $reader = gp_reader::new('mi', $chr);
    }
    else {
	confess "unkown gene_type '$gene_type'";
    }

    my $item;
    while (($item = $reader->get_next()) ne '') {
	# printf STDERR "loaded %d markers\n", $count if ++$count % 1000 == 0; # ZZZ
	my ($id, $name, $chr, $strand, $start, $end, $len, $exons, $introns, @rest) = split(/\t/, $item);
	if ($type =~ /all/) {
	    $markers->add_marker($chr, $strand, $start, $end, $name, $id, $exons, $introns, @rest);
	}
	if ($type =~ /exon/) {
	    for my $exon (split /,/, $exons) {
		my ($start, $len) = split /:/, $exon;
		next if $len <= 0;
		my $end = $start + $len - 1;
		$markers->add_marker($chr, $strand, $start, $end, $name, $id, $exons, $introns, @rest);
	    }
	}
	if ($type =~ /intron/) {
	    for my $intron (split /,/, $introns) {
		my ($start, $len) = split /:/, $intron;
		next if $len <= 0;
		my $end = $start + $len - 1;
		$markers->add_marker($chr, $strand, $start, $end, $name, $id, $exons, $introns, @rest);
	    }
	}
    }

    return;
}

my %affy;

sub load_affy {
    my @affy_array = ::mysql_chomp_noheader("select a.name, b.value, c.value
	    from $table{'known'} a
	    left join $table{'U133'} b on (a.name = b.name)
	    left join $table{'U133Plus2'} c on (a.name = c.name)");
    for my $affy (@affy_array) {
	my ($name, $affy1, $affy2) = split /\t/, $affy;
	$affy{$name} = join("\t", $affy1, $affy2);
    }
}

1;
