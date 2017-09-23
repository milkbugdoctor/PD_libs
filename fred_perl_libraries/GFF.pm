
require 'misc.pl';

package GFF;
use URI::Escape;

use Carp qw{cluck confess};
use IO::Handle;

#
#   GFF::new($file) = $file can be filename or handle
#
sub new {
    my ($file) = @_;
    my $self = {};
    bless $self;
    my $fd;
    if (!($fd = ::get_file_handle($file))) {
        open($fd, $file) || confess "can't open file '$file': $!";
    }
    $self->{fd} = $fd;
    return $self;
}

#
#   $gff->next_entry() : returns hash
#
#   usage:
#	while (my $hash = $gff->next_entry()) {
#	}
#
sub next_entry {
    my $self = shift;
    my $fd = $self->{fd};
    my $hash;
    while (1) {
	$_ = <$fd>;
	last if ! defined $_;
	chomp;
	next if /^#/;
	my ($seqid, $source, $type, $start, $end, $score, $strand, $phase, $attributes) = split /\t/;
	$hash->{seqid} = uri_unescape($seqid);
	$hash->{source} = uri_unescape($source);
	$hash->{type} = uri_unescape($type);
	$hash->{start} = uri_unescape($start);
	$hash->{end} = uri_unescape($end);
	$hash->{score} = uri_unescape($score);
	$hash->{strand} = uri_unescape($strand);
	$hash->{phase} = uri_unescape($phase);
	my @pairs = split /;/, $attributes;
	for my $pair (@pairs) {
	    my ($key, $val) = split /=/, $pair, 2;
	    if ($hash->{$key} eq '') {
		$hash->{$key} = uri_unescape($val);
	    }
	    else {
		$hash->{$key} .= "\n" . uri_unescape($val);
	    }
	}
	for my $key (keys %$hash) {
	    delete $hash->{$key} if $hash->{$key} eq '.';
	}
	last;
    }
    return $hash;
}

1;
