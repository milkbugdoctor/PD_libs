package lister;

sub list {
    my $i;
    my @output;
    for $i (@_) {
        push(@output, $i);
        if (-d $i) {    # traverse directory
            opendir(FOO, "$i");
	    my @entries;
            for $j (readdir(FOO)) {
                next if $j eq '.';
                next if $j eq '..';
		push(@entries, "$i/$j");
            }
	    push(@output, &list(@entries));
        }
    }
    return @output;
}

#
#   Process files, but not directories.
#
sub process_files {
    my ($func) = shift;
    for my $i (@_) {
        if (-d $i) {    # traverse directory
	    my $fd;
            opendir($fd, "$i") || die "can't open directory '$i'";
	    my @entries;
            for $j (readdir($fd)) {
                next if $j eq '.';
                next if $j eq '..';
		push(@entries, "$i/$j");
            }
	    closedir $fd;
	    process_files($func, @entries);
        }
	else {
	    &$func($i);
	}
    }
}


#
#   Process files and directories.
#
sub process_files_and_directories {
    my ($func) = shift;
    for my $i (@_) {
        if (-d $i) {    # traverse directory
	    my $fd;
            opendir($fd, "$i") || warn "can't open directory \"$i\"\n";
	    my @entries;
            for $j (readdir($fd)) {
                next if $j eq '.';
                next if $j eq '..';
		push(@entries, "$i/$j");
            }
	    closedir $fd;
	    &$func($i);
	    process_files_and_directories($func, @entries);
        }
	else {
	    &$func($i);
	}
    }
}

#
#   Process files and chosen directories.
#   If $func() returns 0, the directory will not be traversed.
#
sub process_files_and_directories2 {
    my ($func) = shift;
    for my $i (@_) {
        if (-d $i) {    # traverse directory
	    next if ! &$func($i); # don't traverse
	    my $fd;
            opendir($fd, "$i") || warn "can't open directory \"$i\"\n";
	    my @entries;
            for $j (readdir($fd)) {
                next if $j eq '.';
                next if $j eq '..';
		push(@entries, "$i/$j");
            }
	    closedir $fd;
	    process_files_and_directories2($func, @entries);
        }
	else {
	    &$func($i);
	}
    }
}


#
#   Process directories only.
#
sub process_directories {
    my $func = shift;
    my $depth_first = shift;
    for my $i (@_) {
        if (-d $i) {    # traverse directory
	    &$func($i) if ! $depth_first;
	    my $fd;
            opendir($fd, "$i") || die "can't open directory '$i'";
	    my @entries;
            for $j (readdir($fd)) {
                next if $j eq '.';
                next if $j eq '..';
		my $path = "$i/$j";
	        process_directories($func, $depth_first, $path)
		    if -d $path;
            }
	    closedir $fd;
	    &$func($i) if $depth_first;
        }
    }
}

1;
