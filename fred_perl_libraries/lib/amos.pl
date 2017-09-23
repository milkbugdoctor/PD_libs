
sub get_contig_hash {
    my ($mapfile, $regex) = @_;
    use Columns;

    my %contig_hash;
    open(MAP, $mapfile) or die "$mapfile: $!";
    warn "reading map file $mapfile...\n";
    while (<MAP>) {
        chomp;
        next if /^RED/;
        my ($a, $b, $real_id) = split /\s+/;
        die "$a ne $b" if $a ne $b;
        if ($real_id =~ /$regex/i) {
            $contig_hash{$a} = 1;
        }
    }
    warn "done reading map file\n";
    return \%contig_hash;
}

1;
