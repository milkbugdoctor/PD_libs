
sub set_to_array {
	my $set = $_[0];
	my @result;
	$set =~ s/[\{\}\s]//g;
	my @bits = split(/,/, $set);
	for my $bit (@bits) {
		if ($bit =~ /-/) {
			my ($a, $b) = split(/-/, $bit);
			push(@result, $a .. $b);
		}
		else {
			push(@result, $bit);
		}
	}
	@result = sort { $a <=> $b } @result;
	return @result;
}


1;
