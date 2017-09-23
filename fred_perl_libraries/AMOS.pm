#
#	AMOS.pm
#
#	Author: Fred Jon Edward Long
#
#	Created: Thu Mar 12 00:11:42 PDT 2009

=head1 NAME

AMOS - A library of perl routines.

=head1 SYNOPSIS

use AMOS;

=cut

package AMOS;

use Carp qw{cluck confess};
use strict;

sub get_read_map {
    my ($bankdir) = @_;
    my $mapfile = "$bankdir/RED.map";
    my $fd;
    open($fd, $mapfile) or die "can't open '$mapfile': $!";
    warn "reading map file $mapfile...\n";
    my $hash;
    while (<$fd>) {
        chomp;
        next if /^RED/;
        my ($bid, $iid, $eid) = split /\t/;
	$hash->{$eid} = $iid;
    }
    warn "done reading map file\n";
    return $hash;
}

1;
