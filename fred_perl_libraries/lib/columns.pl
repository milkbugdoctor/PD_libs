
#
#   Old "columns" code.  Known bug: Halts on blank lines.
#

use Carp qw{cluck confess};

our $allow_missing_columns = 1;

require 'misc.pl';

#
#	Get named or numbered columns.
#	Numeric column numbers start at 1.
#

my %header_comments;

sub get_header {
    my ($fd) = @_;
    my $header_comments;
    while (my $line = <$fd>) {
	if ($line =~ /^#/) {
	    $header_comments .= $line;
	    next;
	}
	$line =~ s/[\r\n]+$//;
	my @header = split /\t/, $line, -1;
	$header_comments{join("\t", @header)} = $header_comments;
	return @header;
    }
}

sub get_header_comments {
    return $header_comments{join("\t", @_)};
}

sub print_header {
    my ($fd, @header) = @_;
    my $line = join("\t", @header);
    my $extra = $header_comments{$line};
    print $fd "$extra$line\n";
}

sub print_row {
    my $fd = shift;
    my $line = join("\t", @_);
    print $fd "$line\n";
}

sub get_row {
    my ($fd) = @_;
    if (my $line = <$fd>) {
	$line =~ s/[\n\r]+$//;
	return split /\t/, $line, 900;
    }
    return ();
}

#
#   See if header contains a col from @col
#
sub find_col {
    my ($header, $must, @col) = @_;
    for (my $i = 0; $i < scalar @$header; $i++) {
        my $hcol = ${$header}[$i];
	for my $col (@col) {
	    if ($hcol eq $col) {
		return $col;
	    }
	    if ($col =~ /^\d+$/) { # numeric
		return $hcol if $col == ($i + 1);
	    }
	}
    }
    if ($must) {
	die "can't find column " . join(" or ", @col) . "\n";
    }
    return undef;
}

#
#   Return column name or undef
#
sub has_col {
    my ($header, @col) = @_;
    return find_col($header, 0, @col);
}

#
#   Must have at least one of the columns
#
sub must_col {
    my ($header, @col) = @_;
    return find_col($header, 1, @col);
}

#
#   Must have all of the columns
#
sub must_cols {
    my ($header, @cols) = @_;
    for my $col (@cols) {
	find_col($header, 1, $col);
    }
    return 1;
}

sub get_col {
    my ($header, $row, $col) = @_;
    return (&get_cols)[0];
}

my %hash;

#
#   Return column number, or 0 if not found
#
sub get_col_num {
    my ($header, $col) = @_;
    if ($header eq '') { # assume no header and numeric columns
	die "col '$col' must be >= 1 if no header" if $col == 0;
	return $col;
    }
    my $sep = $"; $" = "\t";
    my $key = "@$header"; $" = $sep;
    my $res = $hash{$key}{$col};
    return $res if defined $res;
    for (my $i = 0; $i < scalar @$header; $i++) {
        my $hcol = ${$header}[$i];
	if ($hcol eq $col) {
	    $hash{$key}{$col} = ($i + 1);
	    return ($i + 1);
	}
	if ($col =~ /^\d+$/) { # numeric
	    if ($col == $i + 1) {
		$hash{$key}{$col} = ($i + 1);
		return ($i + 1);
	    }
	}
    }
    $hash{$key}{$col} = 0;
    return 0;
}

#
#   Return column numbers
#
sub get_col_nums {
    my ($header, @cols) = @_;
    my @res;
    for my $col (@cols) {
	push(@res, get_col_num($header, $col));
    }
    return @res;
}

#
#   Return column names
#
sub get_col_names {
    my ($header, @cols) = @_;
    my @res;
    for my $col (@cols) {
	my $num = get_col_num($header, $col);
	if ($num == 0) {
	    push(@res, undef);
	}
	else {
	    push(@res, $$header[$num - 1]);
	}
    }
    return @res;
}

sub get_cols {
    my ($header, $row, @cols) = @_;
    my @result;
    for my $col (@cols) {
	if (my $i = get_col_num($header, $col)) {
	    if (!defined $row->[$i - 1]) {
		my $tmp = $"; $" = "|";
		cluck "missing column number $i in row [@$row]" unless $allow_missing_columns;
		$" = $tmp;
	    }
	    push(@result, $row->[$i - 1]);
	}
	else {
	    push(@result, undef);
	}
    }
    return @result;
}

sub set_col {
    my ($header, $row, $col, $val) = @_;
    if (my $i = get_col_num($header, $col)) {
	$row->[$i - 1] = $val;
    }
    else {
	confess "could not set missing column '$col'";
    }
}

sub add_col {
    my ($header, @cols) = @_;
    for my $col (@cols) {
	push(@$header, $col) if ! has_col($header, $col);
    }
}

sub find_prefixed_col2 {
    my ($header, $force, $prefixes, $suffixes) = @_;
    my @tried;
    for my $p (@$prefixes) {
	for my $s (@$suffixes) {
	    my $col;
	    return $col if ($col = has_col($header, "${p}_$s"));
	    push(@tried, "${p}_$s");
	}
    }
    die "can't find column " . join(" or ", @tried) if $force;
    return undef;
}

sub find_prefixed_col {
    my ($header, $name, $force, @prefixes) = @_;
    my @tried;
    for my $try (@prefixes) {
        my $col;
        return $col if ($col = has_col($header, "${try}_$name"));
        push(@tried, "${try}_$name");
    }
    return $name if has_col($header, $name);
    push(@tried, "$name");
    die "can't find column " . join(" or ", @tried) if $force;
    return undef;
}


1;
