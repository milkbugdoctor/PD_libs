#	Columns.pm, Fred Jon Edward Long, Fri Oct 28 20:22:46 PDT 2005
#
#	Get named or numbered columns.
#	Numeric column numbers start at 1.

require 'misc.pl';
package Columns;
use Carp qw{cluck confess};

#   Columns::new($file, $no_header) = $file can be filename or handle
#
sub new {
    my ($file, $no_header) = @_;

    my $self = {};
    bless $self;

    my ($header_comments, $fd);
    if ($fd = ::get_file_handle($file)) {
    }
    else {
	open($fd, $file) || confess "can't open file '$file': $!";
    }
    if ($no_header) {
	$self->{'fd'} = $fd;
	$self->{'hash'} = {};
	return $self;
    }
    while (my $line = <$fd>) {
	if ($line =~ /^#/) {
	    $header_comments .= $line;
	    next;
	}
	my $header_block = $header_comments . $line;
	$line =~ s/\s+$//;
	my @header = split /\t/, $line;
	$self->{'fd'} = $fd;
	$self->{'header_comments'} = $header_comments;
	$self->{'header'} = \@header;
	$self->{'input_header'} = [ @header ];
	$self->{'header_block'} = $header_block;
	$self->{'hash'} = {};
	return $self;
    }
}


#
#   get_row() - returns \@row
#
sub get_row {
    my ($self) = @_;
    my $fd = $self->{'fd'};
    if (defined(my $line = <$fd>)) {
	$self->{'row_string'} = $line;
	$self->{line_number}++;
	$line =~ s/[\n\r]+$//;
	return [ split /\t/, $line, -1 ];
    }
    return undef;
}

#
#   get_row_string() - returns last line read
#
sub get_row_string {
    my ($self) = @_;
    return $self->{'row_string'};
}


#   _get_col(\@row, $must_be_there, @cols)
#
sub _get_col {
    my $self = shift;
    my ($row, $must, @cols) = @_;
    confess "\$row is not defined" if ! defined $row;
    my $line_num = $self->{line_number};
    # cluck "empty row at input line $line_num" if @$row == 0 && @{$self->{input_header}} > 1;
    my @result;
    for my $col (@cols) {
	if (my $i = get_col_num($self, 'input_header', $col)) {
	    # my $foo = join("|", @$row);
	    # my $foo = $self->{'row_string'};
	    # cluck "empty column [$col] at input line $line_num [$foo]" if ! defined $row->[$i - 1];
	    push(@result, $row->[$i - 1]);
	}
	else {
	    confess "could not get missing column '$col'" if $must_be_there;
	    push(@result, undef);
	}
    }
    return @result if wantarray;
    return $result[0];
}

sub get_col {
    my $self = shift;
    my ($row, @cols) = @_;
    return _get_col($self, $row, 0, @cols);
}

sub must_get_col {
    my $self = shift;
    my ($row, @cols) = @_;
    return _get_col($self, $row, 1, @cols);
}

#
#   $c->get_header
#
sub get_header {
    my $self = shift;
    my $header = $self->{'header'};
    if (wantarray) {
	return @$header;
    }
    else {
	return $header;
    }
}

sub get_header_comments {
    my $self = shift;
    return $self->{'header_comments'};
}

sub get_header_block {
    my $self = shift;
    return $self->{'header_block'};
}

#
#   print_header($fd) or print_header($fd, $header)
#
sub print_header {
    my ($self, $fd, $h) = @_;
    my $header = $h || $self->{'header'};
    my $extra = $self->{'header_comments'};
    my $line = join("\t", @$header);
    $fd = select if ! defined $fd;
    $fd = ::get_file_handle($fd);
    print $fd "$extra$line\n";
}


#   print_row($fd, \@row)
#
sub print_row {
    my ($self, $fd, $row) = @_;
    my $line = join("\t", @$row);
    $fd = select if ! defined $fd;
    $fd = ::get_file_handle($fd);
    print $fd "$line\n" or confess "can't print to fd '$fd'";
}

#   find_any($must, @cols)
#
#   See if header contains a col from @cols
#
sub find_any {
    my $self = shift;
    my ($must, @col) = @_;
    confess "no columns in list!" if ! @col;
    my $header = $self->{'header'};
    for my $col (@col) {
	for (my $i = 0; $i < scalar @$header; $i++) {
	    my $hcol = $header->[$i];
	    return $col if $hcol eq $col;
	    if ($col =~ /^\d+$/) { # numeric
		return $hcol if $col == ($i + 1);
	    }
	}
    }
    my $columns = join(" or ", @col);
    $header = join(" ", @$header);
    confess "can't find column [$columns] in header [$header]" if $must;
    return undef;
}

#   has_col($col)
#
sub has_col {
    my ($self, $col) = @_;
    return find_any($self, 0, $col);
}

#   has_any(@cols)
#
#   Return column name or undef
#
sub has_any {
    my $self = shift;
    my (@col) = @_;
    return find_any($self, 0, @col);
}

#   must_any(@cols)
#
#   Must have at least one of the columns
#
sub must_any {
    my $self = shift;
    my (@col) = @_;
    return find_any($self, 1, @col);
}

#   must_col($col)
#
#   Must have the column
#
sub must_col {
    my $self = shift;
    my ($col) = @_;
    return find_any($self, 1, $col);
}

#   must_all(@cols)
#
#   Must have all of the columns
#
sub must_all {
    my $self = shift;
    my (@col) = @_;
    for my $col (@cols) {
	find_any($self, 1, $col);
    }
    return 1;
}


#   get_col_num(@cols)
#
#   Return column numbers, 0 if not found
#
sub get_col_num {
    my $self = shift;
    my ($which_header, @cols) = @_;
    my $header = $self->{$which_header};
    my $hash = $self->{'hash'};

    my @result;
    for my $col (@cols) {
	if ($col =~ /^\d+$/) { # numeric
	    push(@result, $col);
	    next;
	}
	my $res = $hash->{$col};
	if (defined $res) {
	    push(@result, $res);
	    next;
	}
	my $val = 0;
	for (my $i = 0; $i < @$header; $i++) {
	    my $hcol = $header->[$i];
	    if ($hcol eq $col) {
		$hash->{$col} = ($i + 1);
		$val = $i + 1;
		last;
	    }
	}
	push(@result, $val);
    }
    return @result if wantarray;
    return $result[0];
}


#   get_col_name(@cols)
#
#   Return column names
#
sub get_col_name {
    my $self = shift;
    my (@cols) = @_;
    my @result;
    my $header = $self->{header};
    for my $col (@cols) {
	if ($col > 0) {
	    push(@result, $header->[$col - 1]);
	}
	else {
	    push(@result, $col);
	}
    }
    return @result if wantarray;
    return $result[0];
}


#   change_col($old_name, $new_name)
#
sub change_col {
    my $self = shift;
    my ($old, $new) = @_;
    if (my $i = get_col_num($self, 'header', $old)) {
	my $header = $self->{'header'};
	$header->[$i - 1] = $new;
    }
    else {
	confess "could not change missing column '$old'";
    }
}


#   $cols->set_col(\@row, $col, $val)
#
sub set_col {
    my $self = shift;
    my ($row, $col, $val) = @_;
    if (my $i = get_col_num($self, 'header', $col)) {
	$row->[$i - 1] = $val;
    }
    else {
	confess "could not set missing column '$col'";
    }
}


#   add_col(@cols)
#
sub add_col {
    my $self = shift;
    my (@cols) = @_;
    my $header = $self->{'header'};
    for my $col (@cols) {
	push(@$header, $col) if ! has_col($self, $col);
    }
}

#   find_prefixed_col2($force, \@prefixes, \@suffixes)
#
sub find_prefixed_col2 {
    my $self = shift;
    my ($force, $prefixes, $suffixes) = @_;
    my (@cols, @tried);
    for my $p (@$prefixes) {
	for my $s (@$suffixes) {
	    push(@cols, ($p eq '') ? $s : "${p}_$s");
	}
    }
    return find_any($self, $force, @cols);
}


#
#   find_prefixed_col($suffix, $force, @prefixes)
#
sub find_prefixed_col {
    my ($self, $name, $force, @prefixes) = @_;
    return find_prefixed_col2($self, $force, \@prefixes, [ $name ]);
}


1;
