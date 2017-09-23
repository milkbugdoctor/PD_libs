
require 'misc.pl';

my $test = 0;

sub file_time {
    my ($file) = @_;
    return (stat($file))[9];
}

sub need {
    my (@args) = @_;
    die "need() called with no parameter!" if @args == 0;
    my $target = pop @args;
    if (!(-e "$target")) {
	warn "need \"$target\"\n";
	return 1;
    }
    my $target_time = file_time($target);
    for $dep (@args) {
	if (-e "$dep" == 0) {
	    die "dependency \"$dep\" does not exist";
	}
    }
    for $dep (@args) {
	my $time = file_time($dep);
	if ($time > $target_time) {
	    warn "need \"$target\"\n";
	    return 1;
	}
    }
    return 0;
}

sub need_nonempty {
    my (@args) = @_;
    die "need() called with no parameter!" if @args == 0;
    my $target = pop @args;
    if ((-s "$target") == 0) {
	warn "need \"$target\"\n";
	return 1;
    }
    my $target_time = file_time($target);
    for $dep (@args) {
	if (-e "$dep" == 0) {
	    die "dependency \"$dep\" does not exist";
	}
    }
    for $dep (@args) {
	my $time = file_time($dep);
	if ($time > $target_time) {
	    warn "need \"$target\"\n";
	    return 1;
	}
    }
    return 0;
}

#
#   Run command
#
sub just_run {
    my @args = @_;
    die "run(): no arguments!" if @args == 0;
    warn "running: @args\n";
    return if $test;
    if (fork() == 0) {
	exec @args;
	exit 1;
    }
    wait;
    return ($? >> 8) == 0;
}

#
#   Run command and die upon errors
#
sub run {
    &just_run || die "command '@_' failed\n";
}

1;

__END__

sub get_first_valid_lock {
    while read host pid
    do
	out=`rsh $host ps --no-headers -p $pid`
	if [ "$out" ]; {
	    echo "$host $pid"
	fi
    done
    echo ""
}

sub locked {
    locked=
    me="`hostname` $$"
    file="$1.lock"
    if [ -s "$file" ]; {
	valid="`cat \"$file\" | get_first_valid_lock`"
	if [ "$valid" -a "$valid" != "$me" ]; {
	    locked=1
	fi
    fi
    [ "$locked" ]
}

sub lock {
    me="`hostname` $$"
    file="$1.lock"
    echo "$me" | lock_and_cat >> "$file"
}

sub unlock {
    rm -f "$1.lock"
}

sub lneed {
    if [ $# -eq 0 ]; {
	echo "need called with no parameter!" 1>&2
	exit 1
    fi
    eval need="\$$#"

    lock $need
    sleep 2
    while locked "$need"; do
	echo $need is locked... 1>&2
	sleep 5
    done

    if ! need $*; {
	unlock $need	# remove my lock
	return 1
    else
	return 0
    fi
}

sub lrun {
    key="$1" ; shift
    echo "lrun [$*] key [$key]" 1>&2
    if locked "$key"; {
	echo "$key is already locked!" 1>&2
	exit 1
    fi
    if [ "$test" -ge 1 ]; {
	return 1
    fi
    if ! eval "$*"; {
	echo "command '$*' failed" 1>&2
	unlock "$key"
	exit 1
    fi
echo "unlocking $key"
    unlock "$key"
}

1;
