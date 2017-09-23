
use Columns;

package marker_reader;

use Carp;

#
#   my $reader = marker_reader::new($file, "cols", @prefixes)
#
#	$file can be filename or handle
#
#   @self = ($columns, $hash, $row);
#
sub new {
    my ($file, $cols, @prefixes) = @_;

    my $columns = Columns::new($file);

    my $self = [];
    bless $self;
    if (@prefixes == 0) { # auto prefix
	my @cols = $columns->get_header();
	if ($cols[0] =~ /^([^_]+)_/) {
	    @prefixes = ($1);
	}
    }
    my @cols = split /\s+/, $cols;
    my $hash = {};
    push(@$self, $columns, $hash, undef);
    for my $col (@cols) {
	my $ncol = $columns->find_prefixed_col($col, 1, @prefixes, '');
	push(@$self, $ncol);
	$hash->{$col} = $ncol;
    }
    return $self;
}

#
#   $reader->read_marker() - returns [ @row ]
#
sub read_marker {
    my ($self) = @_;

    my ($columns, $hash, $row, @cols) = @$self;
    $row = $columns->get_row;
    $self->[2] = $row;
    return undef if ! $row;
    my @row = $columns->get_col($row, @cols);
    return [ @row ];
}

#
#   $reader->get_columns() - returns @columns_used
#
sub get_columns {
    my ($self) = @_;
    my ($columns, $hash, $row, @cols) = @$self;
    return @cols;
}

#
#   $reader->get_col_name(@canonicals)
#
sub get_col_name {
    my ($self, @cols) = @_;

    my ($columns, $hash) = @$self;
    my @ncols;
    for my $col (@cols) {
	my $ncol = $hash->{$col};
	push(@ncols, $hash->{$col});
    }
    return @ncols if wantarray;
    return $ncols[0];
}

#
#   $reader->get_Columns()
#
sub get_Columns {
    my ($self) = @_;
    my ($columns) = @$self;
    return $columns;
}

#
#   $reader->get_row()
#
sub get_row {
    my ($self) = @_;
    my ($columns, $hash, $row) = @$self;
    return $row;
}

1;
