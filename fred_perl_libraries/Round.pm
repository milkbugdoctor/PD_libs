package Round;

sub round_and_trim {
    my ($val, $digits) = @_;
    my $tmp = sprintf("%.*f", $digits, $val);
    $tmp =~ s/\.0+$//;
    return $tmp;
}

1;
