
use IO::Handle;
use Fcntl qw(:DEFAULT :flock);

# printf "%d %d\n", F_WRLCK, F_SETLKW;

sub lock_file {
    my ($fh) = @_;
    flush $fh;
    my $ll = pack("ssllss", F_WRLCK, 0, 0, 0, 0, 0);
    fcntl($fh, F_SETLKW, $ll) || warn("fcntl(F_SETLKW): $!");
}

sub unlock_file {
    my ($fh) = @_;
    flush $fh;
    my $ll = pack("ssllss", F_UNLCK, 0, 0, 0, 0, 0);
    fcntl($fh, F_SETLKW, $ll) || warn("fcntl(F_SETLKW): $!");
}

1;
