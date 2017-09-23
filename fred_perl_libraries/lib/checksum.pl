use Digest::MD5 qw(md5_base64);

sub checksum {
    return md5_base64($_[0]);
}

1;
