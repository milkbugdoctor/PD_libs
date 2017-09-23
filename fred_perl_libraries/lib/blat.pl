
our $std_options = "-minScore=0 -minIdentity=0 -minMatch=1 -tileSize=15 -stepSize=5 -out=pslx";

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
