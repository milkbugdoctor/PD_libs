##############################################################################
#
#   tables.pl - Database table functions for Perl 4
#
#   Tue Oct 26 13:37:19 PDT 1999
#
##############################################################################

sub strip {
	local($cursor) = shift(@_);
	local(@columns) = &isql_columns($cursor);
	local($n) = 0;
	local($type);
	for $i (@_) {
		$type = (split(/[ \(]/, $columns[$n]))[0];
		$i =~ s/^0// if $type eq "DATE";
		$i =~ s/\\0/\\/ if $type eq "DATE";
		$i =~ s/^\$// if $type eq "MONEY";
		$i =~ s/^\$// if $type eq "DECIMAL";
		$n++;
	}
	@_;
}

sub values {
	local($array) = shift(@_);
	local(%row) = @_;
	local(@columns) = eval "@${array}_names";
	local(@row);

	for $i (@columns) {
		push(@row, $row{$i});
	}
	@row;
}

sub insert_row {
	local($array) = shift(@_);
	local(@new) = @_;
	local(@columns) = eval "@${array}_usage";
	local(@types) = eval "@${array}_types";
	local(@keys) = eval "@${array}_keys";
	local($key, @old, $use);

	$key = join($;, @_[@keys]);
	@old = split(/$;/, eval "\$$array{\$key}");
	for ($i = 0; $i <= $#columns; $i++) {
		$use = $columns[$i];
		next if ($use eq "k" || $use eq "n");
		if ($use eq "s") {
			$new[$i] += $old[$i];
		}
		elsif ($use eq "m") {
			if ($types[$i] eq "d") {
				$new[$i] = &Date_min($old[$i], $new[$i]);
			}
			else { $new[$i] = &min($old[$i], $new[$i]); }
		}
		elsif ($use eq "M") {
			if ($types[$i] eq "d") {
				$new[$i] = &Date_max($old[$i], $new[$i]);
			}
			else { $new[$i] = &max($old[$i], $new[$i]); }
		}
	}
	eval "\$$array{\$key} = join(\$;, \@new)";
}

sub define_table {
	local($name, $usage, $columns) = @_;
	local(@names, @types, @keys, @usage);
	local($n) = 0;
	for $i (split(/[ \t\n]+/, $columns)) {
		$i =~ /(\w*):(\w*)/;
		push(@names, $1);
		push(@types, $2);
		eval "\$${name}_column_$1 = $n";
		$n++;
	}
	@usage = split(//, $usage);
	for ($i = 0; $i <= $#usage; $i++) {
		($usage[$i] eq "k") && push(@keys, $i);
	}
	eval "%$name = ()";
	eval "@${name}_usage = \@usage";
	eval "@${name}_names = \@names";
	eval "@${name}_types = \@types";
	eval "@${name}_keys = \@keys";
}

sub row {
	local($array) = shift(@_);
	local(@row) = split(/$;/, shift(@_));
	local(@columns) = eval "@${array}_names";
	local(%result);
	for $c (@columns) {
		$result{$c} = shift(@row);
	}
	%result;
}

sub select {
	local($array) = shift(@_);
	local(@want) = split(/[ \t]+/, shift(@_));
	local(@row) = @_;
	local(@columns) = eval "@${array}_names";
	local($n) = 0;
	local(@result);
	for $w (@want) {
		for ($i = 0; $i < $#columns; $i++) {
			if ($w eq $columns[$i]) {
				push(@result, $row[$i])
			}
		}
	}
	@result;
}

1;
