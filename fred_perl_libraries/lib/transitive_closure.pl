
# input: hash reference
sub transitive_closure {
    my ($in) = @_;
    my $change = 1;
    while ($change) {
        $change = 0;
        for my $key (keys %$in) {
            my $hash1 = $in->{$key};
            for my $key1 (keys %$hash1) {
                my $hash2 = $in->{$key1};
                for my $key2 (keys %$hash2) {
                    if (!$in->{$key}{$key2}) {
                        $in->{$key}{$key2} = 1;
                        $change = 1;
                    }
                }
            }
        }
    }
}

1;
