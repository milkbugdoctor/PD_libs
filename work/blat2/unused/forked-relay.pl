my $std_options = "-minScore=0 -minIdentity=0 -tileSize=8";

use Blat;
use IO::File;
use IO::Pipe;

require 'relay.pl';
require 'tcp.pl';
require 'misc.pl';
require 'filter-blat.pl';

package blat;

my $dir = $ENV{'blat2_work'};
my $chr_file = "$dir/data/chrs";
chomp(my $chr_dir = `cat $dir/data/last_dir`);
die "chr_dir '$chr_dir' not found" if ! -d $chr_dir;

my %sockets;
my $places;
my @chrs = split(/\s+/, `cat $chr_file`);
@chrs = sort sort_chrs @chrs;
die "no chromosomes in $chr_file" if ! @chrs;
for my $chr (@chrs) {
    (my ($host, $port, $pid, $file) = split(/\s+/, `cat $dir/data/$chr.info`))
	|| die "no host/port data for chr '$chr'\n";
    $places{$chr} = "$host $port $pid $file";
    $sockets{$chr} = ::tcp_connect($host, $port) || die "can't connect to $host/$port";
}

#
# Filtered query
#
sub 'blat_chr_query {
    my ($chr, $sequence, $bp, $verbose, $options) = @_;
    ::blat_query($sequence, $bp, $verbose, $options, $chr);
}

sub make_fasta {
    my ($chr, $sequence, $name) = @_;
    $name = "stdin" if $name eq '';
    my $tmp = "/tmp/blat_fasta.$chr.$$";
    my $fd = new IO::File; 
    open($fd, ">$tmp") || die "can't write $tmp";
    print $fd ">$name\n$sequence\n";
    close($fd);
    return $tmp;
}

#
#   Reads big fasta file, writes results to stdout
#
sub 'blat_fasta_query {
    my ($infile, $options, $bp, $verbose, @only_chrs) = @_;

    @only_chrs = @chrs if ! @only_chrs;
    my (%outfiles, %chrs);
    for my $chr (@only_chrs) {
	my $socket = $sockets{$chr};
	die "no host/port data in database for chromosome $chr" if !$socket;
	my ($tmp_fh, $tmpfile) = ::open_tmpfile("/tmp", "blat_fasta_query");
	$outfiles{$chr} = $tmpfile;
	my $pid;
	if (($pid = fork()) == 0) {
	    my $fh;
	    open($fh, $infile) || die "can't read from $infile";
	    my $commandline = get_commandline($chr, $options);
	    print $socket "$commandline\n";
	    $socket->flush();
	    ::multiplex_reader_writer($fh, [ $socket ], [ $socket ], $tmp_fh);
	    exit 0;
	}
	$chrs{$pid} = $chr;
    }
    my $need_header = 1;
    my $header;
    while ((my $pid = wait) != -1) {
	my $chr = $chrs{$pid};
	next if ! defined $chr;
	my $outfile = $outfiles{$chr};
	my $fh;
	open($fh, $outfile) || die "can't read from $outfile";
	while (<$fh>) {
	    last if /^EOF$/;
	    if (want_psl($options)) {
		my ($h, $line) = filter_line($_, $bp, $verbose);
		print $h if $need_header;
		print $line;
	    }
	    else {
		print;
	    }
	}
	unlink $outfile;
	$need_header = 0;
    }
}

sub sort_chrs {
    my $asize = (-s "$chr_dir/$a.nib");
    my $bsize = (-s "$chr_dir/$b.nib");
    return $asize <=> $bsize;
}

sub want_psl {
    my ($options) = @_;
    return 1 if $options !~ /-out=/;
    return $options =~ /-out=psl/;
}

sub get_commandline {
    my ($chr, $options) = @_;
    my $place = $places{$chr};
    my ($host, $port, $pid, $file);
    if (!$place) {
	die "no host/port data found for chromosome $chr";
    }
    else {
        ($host, $port, $pid, $file) = split(/\s+/, $place);
    }
    $options = "$std_options $options" if $std_options;
    $options =~ s/-noHead/-nohead/g;
    return "$file $options";
}

1;
