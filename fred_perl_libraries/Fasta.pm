
package Fasta;

use Carp qw{cluck confess};

#
#   Fasta::new($file, @options) = $file can be filename or handle
#
#   options:
#	cache     - cache any sequences that we read from file
#	cache_all - cache every sequence in the file
#
sub new {
    shift if $_[0] eq 'Fasta';	# allow Fasta::new and "new Fasta"
    my ($file, @options) = @_;
    my $self = {};
    bless $self;
    my $fd;
    if (!($fd = get_file_handle($file))) {
        open($fd, $file) || confess "can't open file '$file': $!";
    }
    $self->{fd} = $fd;
    for my $opt (@options) {
	$opt = lc($opt);
	if ($opt =~ /^(cache.*)$/) {
	    $self->{"opt_$opt"} = 1;
	}
    }
    $self->get_seq_positions(1) if $self->{opt_cache_all};
    return $self;
}

#
#   get positions for sequences in FASTA file
#
sub get_seq_positions {
    my ($self, $load_seqs) = @_;
    $load_seqs = $self->{opt_cache_all} if ! defined $load_seqs;
    warn "get_seq_positions($load_seqs)\n" if $debug;
    my ($pos, $cached);
    return if $load_seqs && $self->{all_cached};
    return if ! $load_seqs && $self->{positions};
    $pos = $self->{positions} = { };
    my $fd = $self->{fd};
    seek($fd, 0, 0) or confess "can't seek";
    my ($key, $first_pos, $last_pos, $seq);
    while (1) {
	$_ = <$fd>;
	if ($_ eq '' || /^>/) {
	    if (defined $key) {
		my $len = ($last_pos - $first_pos);
		$pos->{$key} = "$first_pos $len";
		if ($load_seqs) {
		    $seq =~ s/\s//g if ! is_qual($seq);
		    $self->{cached}->{$key} = $seq;
		}
	    }
	    last if $_ eq '';
	    s/^>//;
	    s/\s.*//s;
	    $key = $_;
	    $first_pos = tell $fd;
	    $last_pos = tell $fd;
	    $seq = '';
	}
	else {
	    $last_pos = tell $fd;
	    $seq .= $_;
	}
    }
    $self->{all_cached} = $load_seqs;
}

sub get_strand_seq {
    my ($self, $key, $strand, $start, $end) = @_;
    my $len = $end - $start + 1;
    my $seq = $self->get_seq($key, $start, $len);
    $seq = rc($seq) if $strand eq '-';
    return $seq;
}

#
#   Return the whole sequence or substring.  Start is 1-based.
#
sub get_seq {
    my ($self, $key, $start, $len) = @_;
    die "get_seq: len cannot be negative" if $len < 0;
    my $cached = $self->{cached};
    my $data = $cached->{$key};
    if (! defined $data) {
	$self->get_seq_positions(); # get positions if necessary
	my $pos = $self->{positions};
	defined $pos->{$key} or confess "can't find '$key'";
	my ($offset, $len) = split /\s+/, $pos->{$key};
	my $fd = $self->{fd};
	seek($fd, $offset, 0) || confess "can't seek to $offset";
	read($fd, $data, $len) || confess "can't read $len bytes";
	$data =~ s/\s//g if ! is_qual($data);
	if ($self->{opt_cache} || $self->{opt_cache_all}) {
	    $delta->{cached}->{$key} = $data;
	}
    }
    if (defined $start and defined $len) {
	if (is_qual($data)) {
	    my $qual = pack_qual($data);
	    return unpack_qual(substr($qual, $start - 1, $len));
	}
	return substr($data, $start - 1, $len);
    }
    else {
	return $data;
    }
}

#
#   Fasta::next_entry($keep_spaces) : returns (key, desc, header, sequence)
#
#   usage:
#	while ((my ($key, $desc, $header, $seq) = $fa->next_entry()) == 4) {
#	}
#
sub next_entry {
    my $self = shift;
    my ($keep_spaces) = @_;
    my $fd = $self->{fd};
    # return undef between files when $fd is ARGV
    if ($self->{eof}) {	  
	$self->{eof} = 0;
	return undef;
    }
    my $header = $self->{next_header};
    my $next_header = '';
    my $sequence;
    while (1) {
	$_ = <$fd>;
	if ($_ eq '') {		# end of file
	    $self->{eof} = 1;
	    last;
	}
        next if /^\s*$/;        # ignore blank lines
        s/(\n|\r)*$//;          # remove newline characters
        if (/^(>.*)/) {
            if ($header) {	# already have a header
                $next_header = $1;
                last;
            }
            else {		# found the header
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
		s/\s*\d+\d*$//;	# remove number at end of line
		$sequence .= $_;
	    }
        }
    }
    $self->{next_header} = $next_header;
    return undef if $header eq '';
    $header =~ /^>(\S+)\s*(.*)/;
    return ($1, $2, $header, $sequence);
}

sub is_qual {
    return ($_[0] =~ /^[\d\s]+$/);
}

sub pack_qual {
    return pack("C*", split(/\s+/, $_[0]));
}

sub unpack_qual {
    return join(' ', unpack("C*", $_[0]));
}

sub rc {
    my ($seq) = @_;
    my $f = 'ACGTKMRYSWBVHDXN';
    my $r = 'TGCAMKYRSWVBDHXN';
    eval "\$seq =~ tr/$f/$r/";
    $f = lc($f);
    $r = lc($r);
    eval "\$seq =~ tr/$f/$r/";
    $seq = scalar reverse $seq;
    return $seq;
}

sub get_file_handle {
    my ($fd) = @_;
    if (eval { ref(*{$fd}{IO}) } =~ /^FileHandle$/) {
        return *{$fd}{IO};
    }
    elsif (eval { ref(*{$fd}{IO}) } =~ /^IO::Handle$/) {
        return $fd;
    }
    return undef;
}

1;
