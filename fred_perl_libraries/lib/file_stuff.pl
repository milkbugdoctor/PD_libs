
package main;

use File::Temp qw/ tempfile /;

sub is_seekable {
    my ($fd) = @_;
    return seek($fd, 0, 1);
}

sub get_seekable {
    my ($fd) = @_;
    return $fd if seek($fd, 0, 1);
    my ($fh, $filename) = tempfile( UNLINK => 1 );
    my $buf;
    while (sysread($fd, $buf, 1024*1024)) {
	print $fh $buf;
    }
    return $fh;
}

sub get_tempfile {
    my ($template) = @_;
    my @params;
    push(@params, $template) if $template ne '';
    push(@params, UNLINK => 1 );
    my ($fh, $filename) = tempfile(@params);
    return ($fh, $filename);
}

1;
