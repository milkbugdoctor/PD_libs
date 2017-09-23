
my $stty = `stty -a 2> /dev/null`;
my $columns = 80;
if ($stty =~ /columns (\d+)/) {
    $columns = $1;
}
elsif ($ENV{COLUMNS} > 0) {
    $columns = $ENV{COLUMNS};
}

sub do_output {
    my (@output) = @{$_[0]};
    my ($header, $format, $widths) = format_lines(@output);
    my $max_length = print_output(0, 0, $header, $format, $widths, @output);
    my $over = $max_length - $columns;
    print_output(1, $over, $header, $format, $widths, @output);
}

sub format_lines {
    my $row = 0;
    my @width;
    my @text;
    for my $line (@_) {
	chomp($line);
	my @line = split /\t/, $line;
	for (my $i = 0; $i <= $#line; $i++) {
	    my $width = length($line[$i]);
	    $width[$i] = $width if $width > $width[$i];
	    $text[$i] = 1 if $row > 0 and ! ($line[$i] =~ /^\d+$/);
	}
	$row++;
    }
    my (@header, @format, @widths);
    for (my $i = 0; $i <= $#width; $i++) {
	push(@widths, $width[$i]);
	push(@header, "%-*.*s");
	if ($text[$i]) {
	    push(@format, "%-*.*s");
	}
	else {
	    push(@format, "%*d");
	}
    }
    return (\@header, \@format, \@widths);
}

#
# $max_len = print_output($print, $over, $header, $format, \@widths, @output);
#
sub print_output {
    my ($print, $reduce, $hr, $fr, $wr, @rest) = @_;
    my $max_len = 0;
    my $line_num = 0;
    my @header = @$hr;
    my @format = @$fr;
    my @widths = @$wr;
    if ($reduce >= 0) {
	$widths[3] -= $reduce;
	$widths[3] = 10 if $widths[3] < 10;
    }
    for my $line (@rest) {
	chomp($line);
	my @line = split /\t/, $line;
	my $output;
	for my $i (0 .. $#header) {
	    my $format;
	    if ($line_num == 0) {
		$format = $header[$i];
	    }
	    else {
		$format = $format[$i];
	    }
	    if ($format =~ /d$/) {
		$output .= sprintf " $format ", $widths[$i], $line[$i];
	    }
	    else {
		$output .= sprintf " $format ", $widths[$i], $widths[$i], $line[$i];
	    }
	}
	$line_num++;
	print "$output\n" if $print;
	$max_len = length($output) if length($output) > $max_len;
    }
    return $max_len;
}

1;
