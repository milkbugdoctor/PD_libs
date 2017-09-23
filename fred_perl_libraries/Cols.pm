#
#	Col.pm
#
#	Author: Fred Jon Edward Long
#
#	Last update: Thu Feb  7 01:13:05 PST 2008
#
#	Get named or numbered columns.
#	Numeric column numbers start at 1.
#	Column names must be unique.


require 'misc.pl';

package Cols;

use Carp qw{cluck confess};

#
#   Cols::new($file, $no_header) = $file can be filename or handle
#
sub new {
    shift if $_[0] eq 'Cols';
    my ($file, $no_header) = @_;

    my $self = {};
    bless $self;

    my ($header_comments, $fd);
    if ($fd = ::get_file_handle($file)) {
    }
    else {
	open($fd, $file) || confess "can't open file '$file': $!";
    }
    while (my $line = <$fd>) {
	if ($line =~ /^#/) {
	    $header_comments .= $line;
	    next;
	}
	$self->{'header_comments'} = $header_comments;
	$self->{'fd'} = $fd;
	if ($no_header) {
	    $self->{next_row} = $line;
	}
	else {
	    $line =~ s/\s+$//;
	    my @header = split /\t/, $line;
	    $self->set_header(@header);
	}
	return $self;
    }
}

#
#   Set input header and output header.
#
sub set_header {
    my $self = shift;
    my @header = @_;
    $self->set_input_header(@header);
    $self->set_output_header(@header);
}

#
#   Set input header.
#
sub set_input_header {
    my $self = shift;
    my @header = @_;
    $self->{input_columns} = [ @header ];
}

#
#   Set output header.
#
sub set_output_header {
    my $self = shift;
    my $header_hash = { };
    my $num = 0;
    my @header;
    for my $h (@_) {
        if (defined $header_hash->{$h}) {
            cluck "column [$h] already used; can't add";
            next;
        }
	$header_hash->{$h} = ++$num;
	$header_hash->{$num} = $num if ! defined $header_hash{$num};
        push(@header, $h);
    }
    $self->{hash} = $header_hash;
    $self->{header} = \@header;
    $self->{header_block} = $self->{'header_comments'} . join("\t", @header) . "\n";
}


#
#   get_row() - returns \%row
#
sub get_row {
    my ($self) = @_;
    my $fd = $self->{'fd'};
    my $line = ($self->{next_row} ne '') ? $self->{next_row} : <$fd>;
    delete $self->{next_row};
    if (defined $line) {
	$self->{row_string} = $line;
	$self->{line_number}++;
	my $line_num = $self->{line_number};
	my $row = { };
	my $header = $self->{'input_columns'};
	$line =~ s/[\n\r]+$//;
	my @cols = split /\t/, $line, -1;
	if (@$header) {
	    for my $col (@$header) {
		$row->{$col} = shift @cols;
	    }
	}
	else {
	    for my $col (1 .. @cols) {
		$row->{$col} = shift @cols;
	    }
	}
	return $row;
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

#
#   get_line_number() - returns current line number
#
sub get_line_number {
    my ($self) = @_;
    return $self->{line_number};
}

sub get_col {
    my $self = shift;
    my ($row, @cols) = @_;
    my @result;
    my $line_num = $self->{line_number};
    for my $col (@cols) {
	push(@result, $row->{$col});
    }
    return @result if wantarray;
    confess "get_col: tried to get multiple columns in scalar context" if @cols > 1;
    return $result[0];
    
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

sub add_header_comments {
    my $self = shift;
    my ($str) = @_;
    $self->{'header_comments'} .= $str;
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
    $fd = select if ! defined $fd;
    my $fh = ::get_file_handle($fd);
    confess "bad file handle [$fd]" if $fh eq '';
    print $fh $self->{'header_comments'};
    my $header = $h || $self->{'header'};
    print $fh join("\t", @$header) . "\n" if @$header;
}


#   $cols->print_row($fd, \%row)
#
sub print_row {
    my ($self, $fd, $row) = @_;
    $fd = select if ! defined $fd;
    $fd = ::get_file_handle($fd);
    my $header = $self->{'header'};
    my @line;
    if (@$header) {
	@line = get_col($self, $row, @$header);
    }
    else {
	# no header, so columns are numbered
	for my $key (sort { $a <=> $b } keys %$row) {
	    push(@line, $row->{$key});
	}
    }
    print $fd join("\t", @line)."\n" or confess "can't print to fd '$fd'";
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

sub has_all {
    my ($self, $must, @cols) = @_;
    for my $col (@cols) {
	if (!has_col($self, $col)) {
	    my $header = $self->{'header'};
	    confess "can't find column [$col] in header [@$header]" if $must;
	    return 0;
	}
    }
    return 1;
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
    has_all($self, 1, @_);
    return 1;
}

#
#   get_col_num(@cols)
#
#   Return column numbers, 0 if not found
#
sub get_col_num {
    my $self = shift;
    my (@cols) = @_;
    my $header = $self->{header};
    my $hash = $self->{hash};

    my @result;
    for my $col (@cols) {
	my $res = $hash->{$col};
	if (defined $res) {
	    push(@result, $res);
	    next;
	}
	elsif ($col =~ /^\d+$/) { # numeric
	    push(@result, $col);
	}
	else {
	    push(@result, 0);
	}
    }
    return @result if wantarray;
    return $result[0];
}

#
#   get_col_name(@cols)
#
#   Return column names
#
sub get_col_name {
    my $self = shift;
    my (@cols) = @_;
    my @result;
    for my $col (@cols) {
	if ($col > 0) {
	    push(@result, $header->[$col]);
	}
	else {
	    push(@result, $col);
	}
    }
    return @result if wantarray;
    return $result[0];
}

#
#   change_col($old_name, $new_name)
#
sub change_col {
    my $self = shift;
    my ($old, $new) = @_;
    my $hash = $self->{hash};
    if (my $i = $hash->{$old}) {
	my $header = $self->{header};
	$header->[$i - 1] = $new;
    }
    else {
	confess "could not change missing column '$old'";
    }
}

#
#   $cols->set_col(\@row, $col, $val)
#
sub set_col {
    my $self = shift;
    my ($row, $col, $val) = @_;
    my $hash = $self->{hash};
    if (defined $hash->{$col}) {
	$row->{$col} = $val;
    }
    else {
	confess "could not set missing column '$col'";
    }
}

#
#   add_col(@cols)
#
sub add_col {
    my $self = shift;
    my (@cols) = @_;
    set_output_header($self, @{$self->{header}}, @cols);
}

#
#   add_col_before(@cols)
#
sub add_col_before {
    my $self = shift;
    my (@cols) = @_;
    set_output_header($self, @cols, @{$self->{header}});
}

#
#   insert_column($pos, @columns)
#
sub insert_column {
    my $self = shift;
    my ($pos, @cols) = @_;
    my $header = $self->{header} or die "huh?";
    my @header = @$header;
    splice(@header, $pos, 0, @cols);
    set_output_header($self, @header);
}

#
#   @cols = find_prefixed_cols($force, \@prefixes, @suffixes)
#
#	Try to find right column for each suffix.
#
sub find_prefixed_cols {
    my $self = shift;
    my ($force, $prefixes, @suffixes) = @_;
    my @result;
    for my $s (@suffixes) {
	my @cols;
	for my $p (@$prefixes) {
	    push(@cols, ($p eq '') ? $s : "${p}_$s");
	    push(@cols, $s) if $p =~ /^none$/i;
	}
	push(@result, find_any($self, $force, @cols));
    }
    return @result;
}


#
#   $col = find_prefixed_col($force, \@prefixes, $suffix)
#
sub find_prefixed_col {
    my ($self, $force, $prefixes, $name) = @_;
    my $col = (find_prefixed_cols($self, $force, $prefixes, $name));
    return $col;
}

1;
