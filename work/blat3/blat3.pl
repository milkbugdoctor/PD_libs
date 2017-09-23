my $debug = 0;

use Blat;
use IO::File;
use IO::Pipe;

require 'relay.pl';
require 'tcp.pl';
require 'filter-blat.pl';

package blat;

my $dir = $ENV{'blat3_work'};
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
warn "finished connecting to all servers\n" if $debug;

sub make_fasta {
    my ($sequence, $name) = @_;
    $name = "stdin" if $name eq '';
    my $tmp = "/tmp/blat3.make_fasta.$$";
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
    ::multiplex_reader_writer($getter, \@wr_files, \@rd_files, $gotter, 0);
}


#
#   Reads big fasta file, writes results to stdout
#
sub 'blat_fasta_query {
    my ($infile, $options, $match, $verbose, @only_chrs) = @_;
    my (%handles, %filenames, %options);
    my $cmd = "cat $infile $dir/flush.fa |";
    open(FASTA, "$cmd") || die "command [$cmd] failed";
    my $need_header = $verbose;
    set_options(\%options, $options, $match);
    my $want_psl = $options{-out};
    $options = flatten_options(\%options);
    my $gotter = sub {
	my ($file, $line) = @_;
	if ($line =~ /^FLUSH1/) {
	    $_[1] = undef;
	    warn "got FLUSH1, $chromosomes{$file} is done\n" if $debug;
	    if ($filenames{$file}) {
		close $handles{$file};
		system "cat $filenames{$file}";
		unlink $filenames{$file};
	    }
	    return;
	}
	if ($want_psl =~ /psl/) {
	    if ($need_header) {
		print_new_psl_header(STDOUT, $want_psl);
		$need_header = 0;
	    }
	    return if $line eq '';
	    $line = filter_psl_line($line, $match, $verbose);
	    print STDOUT $line if $line ne '';
	    return;
	}
	else {
	    if ($handles{$file} eq '') {
		my $fn = fileno($file);
		my $r = rand 100000;
		my $out = "/tmp/blat3-output.$$.$fn.$r";
		my $fh;
		open($fh, "+>$out") || die "can't create $out";
		$handles{$file} = $fh;
		$filenames{$file} = $out;
	    }
	    my $fh = $handles{$file};
	    print $fh $line;
	    $fh->flush();
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
    return "blat $file stdin stdout $options";
}

sub set_options {
    my ($hash, $str, $match) = @_;
    $str = "-out=psl $str";
    for my $opt (split /\s+/, $str) {
	my ($key, $val) = split /=/, $opt;
	$hash->{$key} = $val;
    }
    if ($match =~ /c$/i && $hash->{-out} ne 'pslx') {
	$hash->{-out} = "pslx";
    }
}

sub flatten_options {
    my ($hash) = @_;
    my @result;
    while (my ($key, $val) = each %$hash) {
	if ($val eq '') {
	    push(@result, "$key");
	}
	else {
	    push(@result, "$key=$val");
	}
    }
    my $res = join(" ", @result);
    warn "options $res\n" if $debug;
    return $res;
}

1;
