

#
#   Load hash with the output of the 'printenv' command.
#
sub read_env {
    my ($string) = @_;
    my %hash;
    for my $line (split /\n/, $string) {
	my ($key, $rest) = split /=/, $line, 2;
	$hash{$key} = $rest;
    }
    return %hash;
}

#
#   Load hash with the output of bash's 'set' command.
#
sub read_set {
    my ($string) = @_;
    my %hash;
    for my $line (split /\n/, $string) {
	my ($key, $rest) = split /=/, $line, 2;
	if ($rest =~ /^'(.*)'$/) { $rest = $1; }
	if ($rest =~ /^"(.*)"$/) { $rest = $1; }
	if ($rest =~ /^\$"(.*)"$/) {
	    die "can't handle \$\"";
	}
	if ($rest =~ /^\$'(.*)'$/) {
	    $rest = $1;
	    $rest =~ s/\$/\\\$/g;
	    $rest = eval "\"$rest\"";
	}
	$hash{$key} = $rest;
    }
    return %hash;
}

#
#   Export hash to the environment.
#
sub export_env {
    my (%env) = @_;
    while (my ($key, $val) = each %env) {
	$ENV{$key} = $val;
    }
}

1;
