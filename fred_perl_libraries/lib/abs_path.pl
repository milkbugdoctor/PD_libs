
package abs_path;

use Cwd qw(cwd getcwd abs_path);

#
#   $links:
#      '' - use Cwd::abs_path (expand all symbolic links)
#       0 - expand intermediate symbolic links, but not for final term
#       1 - expand intermediate symbolic links, and only once for final term
#       n - don't expand symbolic links, just give a quick abs path
#   $force:
#       Force it to work with non-existent files.  Otherwise undef is returned.
#
sub ::abs_path {
    my ($file, $links, $force) = @_;

    return undef if ! -e $file && ! $force;

    if ($links eq '') {
	# use Cwd::abs_path for real files
	return Cwd::abs_path($file);
    }

    my $path;
    if ($file =~ m|^/|) {
	$path = "$file";
    }
    else {
	my $cwd = getcwd;
	$cwd .= "/" if substr($cwd, -1) ne "/";
	$path = "$cwd$file";
    }
    # ok, we have a full path now, but it may contain symbolic links
    return fix_path($path) if $links eq 'n';
    my @path = split m|/|, substr($path, 1);
    my $last = pop @path;
    $path = "";
    for my $term (@path) {
	$path = Cwd::abs_path("$path/$term");
    }
    # $links == 0 or 1
    my $link = readlink("$path/$last");
    return Cwd::abs_path("$path/$last") if $link eq ''; # not a symbolic link
    # last item is a symbolic link
    return fix_path("$path/$last") if $links == 0;
    return fix_path($link) if $link =~ m|^/|;
    # got a relative link, so add it to the end
    return fix_path("$path/$link");
}

#
#   Remove /. and /ZZZ/..
#
sub fix_path {
    my $changed = 1;
    while ($changed) {
	$changed = 0;
	$changed += $_[0] =~ s/(.*)\/\.(\/|$)/$1$2/;
	$changed += $_[0] =~ s/\/[^\/]+\/\.\.(\/|$)/$1/;
    }
    return $_[0];
}

1;
