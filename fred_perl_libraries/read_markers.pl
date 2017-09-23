use Carp;
require 'columns.pl';
require 'misc.pl';

my ($chr_col, $strand_col, $pos_col, $end_col, $len_col);

sub find_marker_columns {
    my ($header, @prefixes) = @_;
    $id_col     = find_prefixed_col($header, 'id', 0, @prefixes);
    $chr_col    = find_prefixed_col($header, 'chr', 1, @prefixes);
    $strand_col = find_prefixed_col($header, 'strand', 1, @prefixes);
    $pos_col    = find_prefixed_col($header, 'start', 1, @prefixes);
    $end_col    = find_prefixed_col($header, 'end', 0, @prefixes);
    $len_col    = find_prefixed_col($header, 'len', 0, @prefixes);
    find_prefixed_col2($header, 1, \@prefixes, [ 'end', 'len' ]);
    return ($id_col, $chr_col, $strand_col, $pos_col, $end_col, $len_col);
}

sub get_marker {
    my ($header, $row) = @_;
    my $id     = get_col($header, $row, $id_col);
    my $chr    = get_col($header, $row, $chr_col) || confess "$chr_col column not found";
    my $strand = get_col($header, $row, $strand_col) || confess "$strand_col column not found";
    my $start  = get_col($header, $row, $pos_col) || confess "$pos_col column not found";
    my $end    = get_col($header, $row, $end_col);
    my $len    = get_col($header, $row, $len_col);
    $len = $end - $start + 1 if $len eq '';
    confess "marker length is <= 0" if $len <= 0;
    return ($id, $chr, $strand, $start, $end, $len);
}

1;
