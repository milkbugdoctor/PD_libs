
my $res = eval "use Term::ReadLine;";
my $have_readline = ($@ eq '');
my $term = new Term::ReadLine '' if $have_readline;

sub get {
    my ($prompt, $default) = @_;
    if ($have_readline) {
	return $term->readline("$prompt: ", $default);
    }
    if ($default ne "") {
	get2("$prompt [$default]: ", $default);
    }
    else {
	get2("$prompt: ", $default);
    }
}

sub get2 {
    my ($prompt, $default) = @_;
    print STDERR "$prompt";
    my ($tmp);
    $tmp = <STDIN>;
    $tmp =~ s/\n$//;		# remove trailing \n
    $tmp = $default if $tmp eq '';
    return $tmp;
}

1;
