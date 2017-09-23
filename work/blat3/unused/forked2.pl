my $std_options = "-minScore=0 -minIdentity=0 -tileSize=8";

use Blat;
use IO::File;
use IO::Pipe;

require 'relay.pl';
require 'tcp.pl';
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
    my ($host, $port, $pid, $file);
    (($host, $port, $pid, $file) = split(/\s+/, `cat $dir/data/$chr.info`))
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
#   $getter and $gotter can be function or IO refs
#
sub 'blat_general_query {
    my ($getter, $options, $gotter, @only_chrs) = @_;
    my (@rd_files, @wr_files);
    @only_chrs = @chrs if ! @only_chrs;
    for my $chr (@only_chrs) {
	my $socket = $sockets{$chr};
	if (!$socket) {
	    die "no host/port data in database for chromosome $chr";
	}
	push(@rd_files, $socket);
	push(@wr_files, $socket);
	my $commandline = get_commandline($chr, $options);
	print $socket "$commandline\n";
    }
    my $pipe = new IO::Pipe;
    if ((my $pid = fork()) == 0) { # child
	$pipe->writer();
	::forked_multiplex_reader_writer($getter, \@wr_files, \@rd_files, $pipe);
	close $pipe;
	exit 0;
    }
    else {
	$pipe->reader();
	while(<$pipe>) {
	    my ($index, $line) = split /\t/, $_, 2;
warn "got $line"; #ZZZ
	    &$gotter($index, $line);
        }
    }
}


#
#   Reads big fasta file, writes results to stdout
#
sub 'blat_fasta_query {
    my ($infile, $options, $bp, $verbose, @only_chrs) = @_;
    my (%handles, %filenames, %header);
    open(FASTA, $infile) || die "can't read $infile";
    my $sent_eof = 0;
    my $getter = sub {
	if ($_ = <FASTA>) {
	    return $_;
	}
	else {
	    if ($sent_eof) {
		return undef;
	    }
	    else {
		$sent_eof = 1;
		return "EOF\n";
	    }
	}
    };
    my $gotter = sub {
	my ($file, $line) = @_;
	return undef if $line =~ /^EOF/;
	my $header;
	if (want_psl($options)) {
	    ($header, $line) = filter_psl_line($line, $bp, $verbose);
	}
	$header{$file} .= $header;
	if ($handles{$file} eq '') {
	    my $fn = fileno($file);
	    my $r = rand 100000;
	    my $out = "/tmp/blat.$$.$fn.$r";
	    my $fh;
	    open($fh, ">$out") || die "can't create $out";
	    $handles{$file} = $fh;
	    $filenames{$file} = $out;
	}
	my $fh = $handles{$file};
	print $fh $line;
	$fh->flush();
        return 1;
    };
    ::blat_general_query($getter, $options, $gotter, @only_chrs);
    my ($header) = values %header if $verbose; # only for psl
    print $header;
    for my $file (keys %handles) {
	close $handles{$file};
	my $tmp;
	system "cat $filenames{$file}";
	unlink $filenames{$file};
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
