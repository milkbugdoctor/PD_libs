
use Blat;
use IO::File;
use IO::Pipe;

require 'relay.pl';
require 'tcp.pl';
require 'filter-blat.pl';

my $default_options = "-tileSize=11 -stepSize=11 -minMatch=2 -minScore=30 -minIdentity=90 -out=psl";

my $debug = 0;

package blat;

my $dir = $ENV{'blat2_work'};
my $chr_file = "$dir/data/chrs";
chomp(my $chr_dir = `cat $dir/data/last_dir`);
die "chr_dir '$chr_dir' not found" if ! -d $chr_dir;

my (%sockets, %chromosomes);
my $places;
my @chrs = split(/\s+/, `cat $chr_file`);
@chrs = sort sort_chrs @chrs;
die "no chromosomes in $chr_file" if ! @chrs;
for my $chr (@chrs) {
    (my ($host, $port, $pid, $file) = split(/\s+/, `cat $dir/data/$chr.info`))
	|| die "no host/port data for chr '$chr'\n";
    $places{$chr} = "$host $port $pid $file";
    $sockets{$chr} = ::tcp_connect($host, $port) || die "can't connect to $host/$port";
    $chromosomes{$sockets{$chr}} = $chr;
}

sub make_fasta {
    my ($sequence, $name) = @_;
    $name = "stdin" if $name eq '';
    my $tmp = "/tmp/blat2.make_fasta.$$";
    my $fd = new IO::File; 
    open($fd, ">$tmp") || die "can't write $tmp";
    print $fd ">$name\n$sequence\n";
    close($fd);
    return $tmp;
}

#
#   $getter is an IO handle
#   $gotter can be function or IO ref
#
sub 'blat_general_query {
    my ($getter, $options, $gotter, @only_chrs) = @_;
    my (@rd_files, @wr_files);
    @only_chrs = @chrs if ! @only_chrs;
    for my $chr (@only_chrs) {
	my $socket = $sockets{$chr};
	if (!$socket) {
	    die "no host/port data in database for chromosome '$chr'";
	}
	push(@rd_files, $socket);
	push(@wr_files, $socket);
	my $commandline = get_commandline($chr, $options);
	print $socket "$commandline\n";
	$socket->flush();
    }
    ::multiplex_reader_writer($getter, \@wr_files, \@rd_files, $gotter);
}


#
#   Reads big fasta file, writes results to stdout
#
sub 'blat_fasta_query {
    my ($infile, $options, $match, $verbose, @only_chrs) = @_;
    my (%handles, %filenames, %options);
    open(FASTA, $infile) || die "can't read $infile";
    my $need_header = $verbose;
    set_options(\%options, "$default_options $options");
    if ($match =~ /c$/i && $options{-out} ne 'pslx') {
	$options{-out} = "pslx";
    }
    my $want_psl = $options{-out};
    $options = flatten_options(\%options);
    my $gotter = sub {
	my ($file, $line) = @_;
	if (! defined $line) {
	    warn "$chromosomes{$file} is done\n" if $debug;
	}
	if ($want_psl =~ /psl/) {
	    if ($need_header) {
		print_new_psl_header(STDOUT, $want_psl);
		$need_header = 0;
	    }
	    if ($line ne '') {
		$line = filter_psl_line($line, $match, $verbose);
		print STDOUT $line if $line ne '';
	    }
	    return;
	}
	else {
	    if ($handles{$file} eq '') {
		my $fn = fileno($file);
		my $r = rand 100000;
		my $out = "/tmp/blat2-output.$$.$fn.$r";
		my $fh;
		open($fh, "+>$out") || die "can't create $out";
		$handles{$file} = $fh;
		$filenames{$file} = $out;
	    }
	    my $fh = $handles{$file};
	    print $fh $line;
	    $fh->flush();
	    if (! defined $line) {
		close $fh;
		system "cat $filenames{$file}";
		unlink $filenames{$file};
	    }
	    return;
	}
    };
    ::blat_general_query(*FASTA{IO}, $options, $gotter, @only_chrs);
    close FASTA;
}

sub sort_chrs {
    my $asize = (-s "$chr_dir/$a.nib");
    my $bsize = (-s "$chr_dir/$b.nib");
    return $asize <=> $bsize;
}

#
#   Prepend filename of database file.
#
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
    return "$file $options";
}

sub set_options {
    my ($hash, $str) = @_;
    for my $opt (split /\s+/, $str) {
	my ($key, $val) = split /=/, $opt;
	$hash->{$key} = $val;
    }
}

sub flatten_options {
    my ($hash) = @_;
    my @result;
    while (my ($key, $val) = each %$hash) {
	push(@result, "$key=$val");
    }
    my $res = join(" ", @result);
    warn "options $res\n" if $debug;
    return $res;
}

1;
