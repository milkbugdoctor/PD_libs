##############################################################################
#
#   db_stuff.pl - Database routines for isqlperl and dbperl
#
#   flong@sea.com
#
#   Fri Oct 22 16:05:42 PDT 1999
#
#   Copyright (c) 1999, Systems Engineering Associates; all rights reserved.
#
##############################################################################

require 'misc.pl';

sub get_sqlexec_server {
	if ($sqlexec = $ENV{SQLEXEC}) {
		open(TMP, $sqlexec);
		local(@tmp) = <TMP>;
		close(TMP);
		local(@tmp2) = grep(/[^#]*INFORMIXSERVER=/, @tmp);
		local($tmp3) = $tmp2[$#tmp2];
		$tmp3 =~ s/\n//;
		$tmp3 =~ s/.*INFORMIXSERVER=//;
		local($foo) = `echo $tmp3`;
		$foo =~ s/\n//;
		return $foo;
	}
	return undef;
}


sub db_connect {
	local($dbserver) = $ENV{'INFORMIXSERVER'};
	local($sqlexec) = $ENV{'SQLEXEC'};

	local($server) = &get_sqlexec_server();
	if ($server ne $dbserver) {
		print STDERR <<FOO;

ERROR!\a
\$SQLEXEC="$sqlexec"
The above file sets \$INFORMIXSERVER to "$server", which does not match
the current value of \$INFORMIXSERVER, which is "$dbserver".
Sanity check failed.

FOO
		&die("Could not continue");
		exit 1;
	}

	$isql_autoclose = 1;
	&isql_execute("database $_[0]") || die &isql_msg;
	&isql_execute("set lock mode to wait") || die "Cannot set lock mode";

	return $dbserver;
}


sub fix_row {
	local($cur) = shift @_;
	local(@types) = &isql_columns($cur);
	for $i (@_) {
		if ($types[0] eq "MONEY") {
			$i =~ s/^\$//;
		}
		shift @types;
	}
}


sub get_row {
	local($tmp, @row, @types);

	($tmp = &isql_open($_[0])) || die &isql_msg." Cannot select";
	@row = &isql_fetch($tmp);
	&fix_row($tmp, @row);
	&isql_close($tmp);
	return @row;
}


sub get_table {
	local($tmp, @row, %table);
	($tmp = &isql_open($_[0])) || die &isql_msg." Cannot select";
	while (@row = &isql_fetch($tmp)) {
		$table{$row[$_[1]]} = join($;, @row);
	}
	return %table;
}


sub hash_row {
	local($cursor, @row) = @_;
	local(%hash, @columns, @types);

	if (@columns = &isql_titles($cursor)) {
		@types = &isql_columns($cursor);
		for $i (@columns) {
			$hash{$i} = shift @row;
			if ($types[0] eq "MONEY") {
				$hash{$i} =~ s/^\$//;
			}
			shift @types;
		}
		return %hash;
	}
	return undef;
}


sub get_row_hash {
	local($tmp, @row, %hash);
	($tmp = &isql_open(@_)) || die &isql_msg." Cannot select: $_[0]";
	@row = &isql_fetch($tmp);
	%hash = &hash_row($tmp, @row);
	&isql_close($tmp);
	return %hash;
}


sub print_hash {
	local(%hash) = @_;
	local($key, $val);
	while (($key, $val) = each %hash) {
		print "$key: $val\n";
	}
	print "\n";
}


sub print_cursor {
	local(@tmp) = &isql_titles($_[0]);
	print "@tmp\n";
	while (@row = &isql_fetch($_[0])) {
		print "@row\n";
	}
	print "----\n";
}


sub print_table {
	print "$_[0]:\n";
	local($foo) = &isql_open("select * from $_[0]");
	&print_cursor($foo);
}


1;
