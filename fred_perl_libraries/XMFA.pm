
package XMFA;

use Carp qw{cluck confess};

#
#   Usage:
#       my $xmfa = XMFA::new($file) 
#       my $xmfa = new XMFA($file)
#
#   $file can be a filename or handle
#
sub new {
    shift if $_[0] eq 'XMFA';	# allow XMFA::new or "new XMFA"
    my ($file) = @_;
    my $self = {};
    bless $self;
    my $fd;
    if (!($fd = get_file_handle($file))) {
        open($fd, $file) || confess "can't open file '$file': $!";
    }
    $self->{fd} = $fd;
    return $self;
}

#
#   Usage:
#
#   while ((@entry = $fa->next_entry()) == 6) {
#       ($num, $start, $end, $strand, $desc, $seq) = @entry;
#   }
#
sub next_entry {
    my $self = shift;
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
        next if /^#/;           # ignore # lines
        next if /^=/;           # ignore = lines
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
            my $line = $_;
            s/\s//g;
            die "strange sequence line: [$line] bad: [$1]" if /([^-A-Z])/i;
            $sequence .= $_;
        }
    }
    $self->{next_header} = $next_header;
    return undef if $header eq '';
    $header =~ /^>\s*(\d+):(\d+)-(\d+)\s+([-+])\s+(.*)/;
    return ($1, $2, $3, $4, $5, $sequence);
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
