require 'misc.pl';

use FileHandle;
use Carp qw{confess};

my (%next_header, %eof);

#
#   read_fasta3(FILE, $keep_spaces) : returns (key, desc, sequence)
#
#   usage:
#	while ((my ($key, $desc, $seq) = read_fasta3(FILE)) == 3) {
#	}
#
sub read_fasta3 {
    my ($header, $seq) = my @stuff = &read_fasta;
    if (@stuff == 2) {
	$header =~ s/^>//;
	my ($key, $rest) = split /\s+/, $header, 2;
	return ($key, $rest, $seq);
    }
    return undef;
}

#
#   read_fasta_header(FILE) : returns (header, key, description)
#
#   usage:
#	while ((my ($header, $key, $desc) = read_fasta_header(FILE)) == 3) {
#	}
#
sub read_fasta_header {
    my ($fd) = @_;
    while (<$fd>) {
	if (/^>((\S+)\s*([^\r\n]*))/) {
	    return ($1, $2, $3);
	}
    }
    return undef;
}

#
#   read_fasta(FILE, $keep_spaces) : returns (header, sequence)
#
#   $keep_spaces = 0 : reformat and strip spaces
#		   1 : reformat but keep spaces
#                  2 : don't reformat
#
#   usage:
#	while ((my ($header, $seq) = read_fasta(FILE)) == 2) {
#	}
#
sub read_fasta {
    my ($fd, $keep_spaces) = @_;
    if ($eof{$fd}) {
	$eof{$fd} = 0;
	return undef;
    }
    my ($header, $sequence) = ($next_header{$fd});
    my $next_header = '';
    my $no = 0;
    while (1) {
	$_ = <$fd>;
	if ($_ eq '') {		# end of file
	    $no = 1;
	    $eof{$fd} = 1;
	    last;
	}
	if ($keep_spaces == 2) {
	    if (/^(>.*)/) {
		if ($header) {
		    $next_header = $1;
		    last;
		}
		else {
		    $header = $1;
		    $next_header = '';
		}
	    }
	    else {
		die "missing fasta header" if ! $header && ! /^\s*$/;
		$sequence .= $_;
	    }
	    next;
	}
	next if /^\s*$/;        # ignore blank lines
	s/(\n|\r)*$//;          # remove newline characters
        if (/^(>.*)/) {
            if ($header) {
                $next_header = $1;
                last;
            }
            else {
                $header = $1;
                $next_header = '';
            }
        }
        else {
            die "missing fasta header" if ! $header;
	    if (/^[\d\s]+$/ or $keep_spaces) {
		s/\s+$//;
		$sequence .= "$_ ";
	    }
	    else {
		my $line = $_;
		s/\s//g;
		s/^\s*\d+\d*//;	# remove number at start of line
		s/\s*\d+\d*$//;	# remoev number at end of line
		die "aborting: strange sequence line: [$line]" if /[^\-A-Z*]/i;
		$sequence .= $_;
	    }
        }
    }
    $next_header{$fd} = $next_header;
    return undef if ! $header && ! $sequence;
    return ($header, $sequence);
}


#	* OLD *
#
#	read_fasta_entry(FILE-HANDLE)
#
#	returns (done?, header, sequence)
#
#	When $done is true EOF has been hit and
#	$header and $sequence will contain the last
#	entry, unless the file was empty.
#
my $next_header;
sub read_fasta_entry {
    my ($fd) = @_;
    my ($header, $sequence) = ($next_header);
    $next_header = '';

    my $no = 0;
    while (1) {
	$_ = <$fd>;
	if ($_ eq '') {		# end of file
	    $no = 1;
	    last;
	}
        next if /^\s*$/;        # ignore blank lines
        s/(\n|\r)*$//;          # remove newline characters
        if (/^(>.*)/) {
            if ($header) {
                $next_header = $1;
                last;
            }
            else {
                $header = $1;
                $next_header = '';
            }
        }
        else {
            die "missing fasta header" if ! $header;
            s/\s//g;
            $sequence .= $_;
        }
    }
    return (1) if ! $header && ! $sequence;
    return ($no, $header, $sequence);
}


#
# returns \%hash
#
sub fasta_file_to_hash {
    my ($file) = @_;
    my $fd;
    if (!($fd = ::get_file_handle($file))) {
        open($fd, $file) || confess "can't open file '$file': $!";
    }
    my %hash;
    my $order = 1;
    while ((my ($header, $seq) = read_fasta($fd)) == 2) {
	$header =~ s/^>//;
	$header =~ /^(\S+)(\s+(.+)\s*$)?/;
	my $key = $1;
	my $desc = $3;
	$hash{$key}{header} = $header;
	$hash{$key}{desc} = $desc;
	$hash{$key}{seq} = $seq;
	$hash{$key}{order} = $order++;
    }
    close($fd);
    return \%hash;
}


#
# returns \@names, \@sequences
#
sub read_fasta_filename {
    my ($filename) = @_;
    my $fd = new FileHandle;
    my ($names, $seqs) = ([], []);
    my $seq_num = -1;
    open($fd, $filename) || die "couldn't open $filename";
    while (<$fd>) {
	s/(\n|\r)*$//;
	if (/^>(.*)/) {
	    $seq_num++;
	    $$names[$seq_num] = $1;
	}
	else {
	    if ($seq_num < 0) {
		$seq_num = 0;
		$$names[$seq_num] = "none";
	    }
	    s/\s//g;
	    $$seqs[$seq_num] .= $_;
	}
    }
    close($fd);
    return ($names, $seqs);
}

#
# returns \@names, \@sequences
#
sub read_fasta_file {
    my ($fd) = @_;
    my ($names, $seqs) = ([], []);
    my $seq_num = -1;
    while (<$fd>) {
	chomp;
	if (/^>(.*)/) {
	    $seq_num++;
	    $$names[$seq_num] = $1;
	}
	else {
	    if ($seq_num < 0) {
		$seq_num = 0;
		$$names[$seq_num] = "none";
	    }
	    s/\s//g;
	    $$seqs[$seq_num] .= $_;
	}
    }
    close($fd);
    return ($names, $seqs);
}

sub read_fasta_string {
    my @lines = split(/\n/, $_[0]);
    my ($names, $seqs) = ([], []);
    my $seq_num = -1;
    for (@lines) {
	chomp;
	if (/^>(.*)/) {
	    $seq_num++;
	    $$names[$seq_num] = $1;
	}
	else {
	    if ($seq_num < 0) {
		$seq_num = 0;
		$$names[$seq_num] = "none";
	    }
	    s/\s//g;
	    $$seqs[$seq_num] .= $_;
	}
    }
    return ($names, $seqs);
}

sub get_tens {
    my $tmp = $_[0];
    my @tmp = split(/(..........)/, $tmp);
    @tmp = grep(/./, @tmp);
    my $out;
    while (my @foo = splice(@tmp, 0, 7)) {
	$out .= "@foo\n";
    }
    return $out;
}

sub print_tens {
    my ($fd, $tmp) = @_;
    my @tmp = split(/(..........)/, $tmp);
    @tmp = grep(/./, @tmp);
    while (my @foo = splice(@tmp, 0, 7)) {
        print $fd "@foo\n";
    }
}

sub is_qual {
    return ($_[0] =~ /^[\d\s]+$/);
}

sub print_wrapped {
    my ($fd, $tmp, $cols, $keep_spaces) = @_;
    if ($tmp =~ /^[\d\s]+$/) {	# qual data
	my @words = split /\s+/, $tmp;
	while (@words) {
	    my @line = splice(@words, 0, 17);
	    print $fd join(" ", @line), "\n";
	}
	return;
    }
    if (! $keep_spaces && $tmp =~ /^[^\d]+$/s) {
	$tmp =~ s/\s+//g;
    }
    my $len = length($tmp);
    $cols = 75 if $cols < 1;
    for (my $i = 0; $i < $len; $i += $cols) {
        print $fd substr($tmp, $i, $cols), "\n";
    }
}

sub print_numbered {
    my ($fd, $num, $tmp) = @_;
    my $len = length($tmp);
    my $start = 1;
    for (my $i = 0; $i < $len; $i += $num) {
        printf($fd "%-10d%s\n", $start, substr($tmp, $i, $num));
	$start += length(substr($tmp, $i, $num));
    }
}

sub pack_qual {
    return pack("C*", split(/\s+/, $_[0]));
}

sub unpack_qual {
    return join(' ', unpack("C*", $_[0]));
}

1;
