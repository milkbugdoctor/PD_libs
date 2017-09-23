
our $debug;

eval `job.config -p`;
die "JOBS_DIR not defined" if $JOBS_DIR eq '';
die "JOBS_DIR [$JOBS_DIR] not found" if ! -d $JOBS_DIR;

require "tcp.pl";
require 'timed_read.pl';

$run_as_root = 1;
$stall_time = 60;
$server_port = 147092;

$job_db    = 'jobs';
$job_table = 'jobs';
$command_table = 'commands';
$default_queue = 'main';

$log_dir = "$JOBS_DIR/logs";
$logfile = "$log_dir/run.log";
our $host_file = "$JOBS_DIR/job.hosts";
our $dbh;
our $locked = 0;
our $counnected = 0;

##############################################################################

use Carp qw{cluck confess};
use DBI;
require "lock.pl";
require "misc.pl";

chomp($current_host = `hostname`);
chomp($ENV{'LOGNAME'} = `id -n -u -r`);
$logname = $current_user = $ENV{'LOGNAME'};
my $ping_time = "(unix_timestamp() - unix_timestamp(ping_time))";

sub I_am_superuser {
    return $current_user =~ /^(root|flong)$/;
}
sub I_am_root {
    return $current_user eq 'root';
}

sub jobs_connect {
    if ($connected++ == 0) {
	my $database = $job_db;
	my $hostname = $job_host;
	my $user     = $job_user;
	my $password = $job_pass;
	my $dsn = "DBI:mysql:database=$database;host=$hostname";
	($dbh = DBI->connect($dsn, $user, $password)) || confess "DBI->connect: $!";
    }
}

sub jobs_disconnect_safely {
    $dbh->{InactiveDestroy} = 1;
    undef $dbh;
    $locked = $connected = 0;
}

sub jobs_disconnect {
    if (--$connected <= 0) {
	$dbh->disconnect;
	$connected = 0;
    }
}

sub job_update {
    my ($id, $field, $value) = @_;
    &write_lock;
    $dbh->do("update $job_table set $field = ? where id = $id", undef, $value);
    &unlock;
}

sub job_updates {
    my ($field, $value, @ids) = @_;
    &write_lock;
    for my $id (@ids) {
	$dbh->do("update $job_table set $field = ? where id = $id", undef, $value);
    }
    &unlock;
}

sub job_updates2 {
    my ($field, $value, @ids) = @_;
    &write_lock;
    for my $id (@ids) {
	$dbh->do("update $job_table set $field = $value where id = $id", undef) || die $sth->errstr;
    }
    &unlock;
}

#
#   Use for special functions, like now()
#
sub job_update2 {
    my ($id, $field, $value) = @_;
    &write_lock;
    $dbh->do("update $job_table set $field = $value where id = $id");
    &unlock;
}

sub jobs_update_status {
    my ($status, @ids) = @_;
    return if ! @ids;
    my $ids = join(",", @ids);
    &write_lock;
    confess "$!" if ! defined
	$dbh->do("update $job_table set status = '$status' where id in ($ids)");
    &unlock;
}

sub job_hash {
    my ($id) = @_;
    my $cmd = "select * from $job_table where id = $id";
    my $sth = $dbh->prepare($cmd) || confess "job_hash: [$cmd] failed: " . $sth->errstr;
    $sth->execute() || confess "job_hash: [$cmd] failed: " . $sth->errstr;
    my $hash = $sth->fetchrow_hashref();
    return %$hash;
}

sub job_hashes {
    my (@ids) = @_;
    my @result;
    return @result if @ids == 0;
    my $ids = join(",", @ids);
    my $cmd = "select * from $job_table where id in ($ids)";
    my $sth = $dbh->prepare($cmd) || confess "[$cmd] failed: " . $sth->errstr;
    $sth->execute() || confess "[$cmd] failed: " . $sth->errstr;
    while (my $hash = $sth->fetchrow_hashref()) {
	push(@result, $hash);
    }
    return @result;
}

sub job_info {
    my ($id, @cols) = @_;
    my $cols = join ",", @cols;
    my $cmd = "select $cols from $job_table where id = $id";
    &read_lock;
    my $sth = $dbh->prepare($cmd);
    $sth->execute() || confess "job_info: [$cmd] failed: " . $sth->errstr;
    my @row = $sth->fetchrow_array();
    $sth->finish();
    &unlock;
    return @row;
}

sub job_text {
    my ($id) = @_;
    my $cmd = "select jobtext from $command_table where id = $id";
    &read_lock;
    my $sth = $dbh->prepare($cmd);
    $sth->execute() || do {
	&unlock;
	warn "job_text: [$cmd] failed: $!\n";
	return '';
    };
    my @row = $sth->fetchrow_array();
    $sth->finish();
    &unlock;
    return $row[0];
}

sub job_status {
    my ($status) = job_info($_[0], 'status');
    return $status;
}

sub read_lock {
    warn "read_lock($locked)\n" if $debug;
    return if $locked++;
    warn "-> lock tables\n" if $debug;
    $dbh->do("lock tables $job_table read, $command_table read;") || confess "can't lock $job_table";
}

sub write_lock {
    warn "write_lock($locked)\n" if $debug;
    return if $locked++;
    warn "-> lock tables\n" if $debug;
    $dbh->do("lock tables $job_table write, $command_table write;") || confess "can't lock $job_table";
}

sub unlock {
    warn "unlock($locked)\n" if $debug;
    return if --$locked > 0;
    warn "-> unlock tables\n" if $debug;
    $dbh->do("unlock tables;") || cluck "can't unlock table $job_table";
}

sub add_job {
    my ($job_desc, $cmdtext, %options) = @_;

    my $run_host = $options{run_host};
    $run_host = 'any' if $run_host eq '';
    confess "got empty job" if $cmdtext eq '';
    my $this_host = $current_host;
    $ENV{'job_desc'} = $job_desc;
    $options{queue} = $default_queue if $options{queue} eq '';

    $cmdtext = `$JOBS_DIR/job.setup` . $cmdtext;

    &write_lock;
    my ($id)  = $dbh->selectrow_array("select max(id) from $job_table");
    confess "can't get max(id)" if defined $dbh->err;
    $id++;

    my $str = "
	insert into $job_table
	    (id, user, submit_host, name, submit_time, status, run_host,
		niceness, max_retries, retries, queue)
	values ($id, '$ENV{'LOGNAME'}', '$this_host', ?, now(), 'waiting', ?, ?, ?, ?, ?);
    ";
    my $result = $dbh->do($str, undef, $ENV{job_desc}, $run_host, $options{niceness}+0,
	$options{retries}+0, $options{retries}+0, $options{queue});
    if (! defined $result) {
	&unlock;
	confess "Failed to add job:\n$cmdtext\n";
    }
    # my $id = $dbh->last_insert_id(undef, undef, $job_table, 'id');
    # confess "can't get new id" if ! defined $id;

    $str = "
	insert into $command_table (id, jobtext)
	values ($id, ?)
    ";
    $result = $dbh->do($str, undef, $cmdtext);
    if (! defined $result) {
	&unlock;
	confess "Failed to add job text:\n$cmdtext\n";
    }

    &unlock;

    # &log_job_add;
}

sub add_log_entry {
    my ($text) = @_;
    chmod 0777, $logfile;
    open(FOO, ">>$logfile") || warn "job.add: can't append to $logfile\n";
    lock_file(FOO);
    my $date = &get_time;
    print FOO "[$current_host] [$date] $text\n";
    unlock_file(FOO);
    close FOO;
    chmod 0777, $logfile;
}

sub log_job_add {
    my $text = "Job '$ENV{job_desc}' added by ${logname}\n";
    my @lines = split /\n/, $commands;
    @lines = splice(@lines, 0, 4);
    $text .= "\t" . join("\n\t", @lines) . "\n";
    add_log_entry($text);
}

sub do_select {
    my ($query, $die_on_error, $no_header)  = @_;
    my @result;
    &read_lock;
    my $sth = $dbh->prepare($query);
    $sth->execute() || do {
        &unlock;
	warn "do_select: [$query] failed: $!\n";
	exit 1 if $die_on_error;
	return '';
    };
    my @cols;
    for my $i (1 .. $sth->{NUM_OF_FIELDS}) {
	push(@cols, $sth->{NAME}->[$i - 1]);
    }
    while (my @row = $sth->fetchrow_array()) {
	push(@result, join("\t", @row));
    }
    &unlock;
    unshift(@result, join("\t", @cols)) if @result && ! $no_header;
    return @result;
}

my $timeout = 30;

sub handle_alarm {
    die "job.grabber: timeout ($timeout) on getting next job\n";
}

sub next_job {
    my ($queue, $max_jobs, $connect) = @_;
    $SIG{'ALRM'} = 'handle_alarm';
    alarm($timeout);
    if ($connect) {
	&jobs_connect;
	&write_lock;
    }
    my $cmd = "select id, user, niceness from $job_table 
	where status = 'waiting' and ('$current_host' regexp run_host or run_host = 'any')
	and (queue = '$queue' or '$queue' = 'any')
	order by id limit $max_jobs";
    my $rows = $dbh->selectall_arrayref($cmd);
    if ($rows eq '') {
	warn "cmd failed: $cmd\n";
    }
    if ($connect) {
	&unlock;
	&jobs_disconnect;
    }
    alarm(0);
    $SIG{'ALRM'} = 'IGNORE';
    return @$rows;
}

sub next_jobs {
    my ($queue, $max_jobs, $connect) = @_;
    $SIG{'ALRM'} = 'handle_alarm';
    alarm($timeout);
    if ($connect) {
	&jobs_connect;
	&write_lock;
    }
    my @rows;
    my $cmd = "select * from $job_table 
	where status = 'waiting' and ('$current_host' regexp run_host or run_host = 'any')
	and (queue = '$queue' or '$queue' = 'any')
	order by id limit $max_jobs";
    my $sth = $dbh->prepare($cmd) || confess "next_jobs: [$cmd] failed: " . $sth->errstr;
    $sth->execute() || confess "next_jobs: [$cmd] failed: " . $sth->errstr;
    while (my $hash = $sth->fetchrow_hashref()) {
	push(@rows, $hash);
    }
    if ($connect) {
	&unlock;
	&jobs_disconnect;
    }
    alarm(0);
    $SIG{'ALRM'} = 'IGNORE';
    return @rows;
}

sub get_time {
    chomp(my $time = `date '+%x %r'`);
    return $time;
}

sub match_state {
    my ($state) = @_;
    if ($state =~ /^runn/i) {
	return 'running';
    }
    elsif ($state =~ /^wait/i) {
	return 'waiting';
    }
    elsif ($state =~ /^paus/i) {
	return 'paused';
    }
    elsif ($state =~ /^hand/i) {
	return 'handing off';
    }
    elsif ($state =~ /^done/i) {
	return 'done';
    }
    elsif ($state =~ /^fail/i) {
	return 'failed';
    }
    elsif ($state =~ /^kill/i) {
	return 'killed';
    }
    return '';
}

our $select_jobs_usage = "

        job-id
        job-pattern
        'all'           select all jobs
        state		done, failed, killed, running, waiting
        -s state        done, failed, killed, running, waiting
        -u user
	-rh run_host    host job is running on
";

our $change_jobs_usage = "

        -ns state       new state (clean, rerun)
	-h run_host     new run_host pattern
";

sub select_jobs {
    my @res = &select_jobs2;
    if (@res >= 1) {
	shift @res; # remove state
	return \@res;
    }
    else {
	return undef;
    }
}

#
#   ($state, @ids) = select_jobs2(...)
#
sub select_jobs2 {
    my (@args) = grep(/\S/, @_);

    @args || die "\nUsage: $0 <job-selection parameters>

    <job-selection parameters>: $select_jobs_usage\n";

    my ($user, $run_host, @pattern);
    my $local_debug = $debug;
    if (!I_am_root()) {
	$user = $current_user;
    }
    while ($args[0]) {
	if ($args[0] eq "-u") {
	    if (I_am_superuser) {
		shift @args;
		$user = shift @args;
	    }
	    else {
		die "\nOnly a superuser can use the -u option.\n\n";
	    }
	}
	elsif ($args[0] eq "all") {
	    $state = '';
	    $run_host = '';
	    shift @args;
	}
	elsif ($args[0] eq "-rh") {
	    shift @args;
	    $run_host = shift @args;
	}
	elsif ($args[0] =~ /^(-[dt])$/) {
	    $local_debug = 1;
	    shift @args;
	}
	elsif ($args[0] eq "-s") {
	    shift @args;
	    if (my $canon = match_state(shift @args)) {
		$state = $canon;
	    }
	}
	elsif (my $canon = match_state($args[0])) {	# any arg can be state
	    $state = $canon;
	    shift @args;
	}
	elsif ($args[0] =~ /^-/) {
	    die "Unknown option '$args[0]'";
	}
	else {
	    push(@pattern, $args[0]);
	    shift @args;
	}
    }

    warn "select_jobs: user=$user host=$host running_host=$run_host state=$state pattern=@pattern\n\n" if $local_debug;

    my @where = ("where 1");
    my (@pattern_clause, @id_clause);
    push(@where, " and user like '$user'") if $user ne '';
    for my $pattern (@pattern) {
	if ($pattern =~ /^\d+$/) {
	    push(@id_clause, "id = $pattern");
	}
	else {
	    push(@pattern_clause, "name like '%$pattern%'");
	}
    }
    die "can't mix patterns with ids\n" if @id_clause && @pattern_clause;
    if (!@id_clause) {
	push(@pattern_clause, "running_host = '$run_host'") if $run_host ne '' && $run_host ne 'any';
	push(@pattern_clause, "status = '$state'") if $state ne '' && $state ne 'any';
    }
    my @or_clause;
    my $id_clause = join(" or ", @id_clause);
    warn "id_clause: $id_clause\n" if $local_debug;
    push(@or_clause, "( $id_clause )") if $id_clause ne '';
    my $pattern_clause = join(" and ", @pattern_clause);
    warn "pattern_clause: $pattern_clause\n" if $local_debug;
    push(@or_clause, "( $pattern_clause )") if $pattern_clause ne '';
    my $or_clause = join(" or ", @or_clause);
    warn "or_clause: $or_clause\n" if $local_debug;
    push(@where, "and ($or_clause)") if $or_clause;

    warn "where: @where\n" if $local_debug;
    my $cmd = "select id from $job_table @where";
    my $sth = $dbh->prepare($cmd) || confess "[$cmd] failed: " . $sth->errstr;
    $sth->execute() || confess "[$cmd] failed: " . $sth->errstr;
    my @ids;
    while (my @row = $sth->fetchrow_array()) {
	push(@ids, $row[0]);
    }
    $sth->finish();

    return ($state, @ids);
}


sub change_state {
    # @params are used to select jobs
    # %option is used to specify new state
    my (@params, %option, $new_state, @ids);
    while (@_) {
	if ($_[0] eq "-h") {	# new run_host
	    shift;
	    $option{host} = shift;
	}
	elsif ($_[0] =~ "^-d") {
	    $option{debug} = $debug = shift;
	}
	elsif ($_[0] =~ "^-ns") {
	    shift;
	    $option{new_state} = $new_state = shift;
	    return 0 if $new_state !~ /^(rerun|clean)$/;
	}
	elsif ($_[0] =~ /^-t/) {
	    $option{test} = $test = shift;
	    $option{debug} = $debug = 1;
	}
	elsif ($_[0] =~ /^-[su]/) {
	    push(@params, shift);
	}
	elsif ($_[0] =~ /^-/) {
	    # return error so caller can print usage info
	    return 0;
	}
	else {
	    my $param = shift;
	    push(@params, $param);
	    push(@ids, $param) if $param =~ /^\d+$/;
	}
    }
    printf STDERR "new state params: %s\n", join(" ", %option) if $debug;
    print STDERR "job_select params: @params\n" if $debug;
    if ($option{host} eq '' && $option{new_state} eq '') {
	# need to set run_host or new state
	return 0;
    }
    return 0 if @params == 0;

    &jobs_connect;
    &write_lock;

    warn "getting ids for params=@params\n" if $debug;
    my $ids = select_jobs(@params);

    @ids = @$ids;

    printf STDERR "got %d ids\n", scalar @ids if $debug;
    if (@ids == 0) {
	warn "no jobs matched\n" if $debug;
	exit 0;
    }

    if ($option{test}) {
	$sth = $dbh->prepare("select id, user, name, submit_time
	    from $job_table
	    where id in (" . join(",", @ids) . ")");
	$sth->execute();
	while (my @row = $sth->fetchrow_array()) {
	    print "@row\n";
	}
	$sth->finish();
	exit 0;
    }

    if ($new_state eq '') {
	if ($option{host}) {
	    job_updates('run_host', $option{host}, @ids);
	}
    }
    elsif ($new_state eq 'rerun') {
	if ($option{host}) {
	    job_updates('run_host', $option{host}, @ids);
	}
	job_updates2('retries', 'max_retries', @ids);
	jobs_update_status('waiting', @ids);
    }
    elsif ($new_state eq 'clean') {
	clean_jobs(@ids);
    }
    else {
	warn "unknown new state '$new_state'\n";
    }

    &unlock;

    exit 0;
}

sub clean_jobs {
    my (@ids) = @_;
    my $ids = join(",", @ids);
    my @hashes = job_hashes(@ids);
    my @files;
    for my $hash(@hashes) {
	my $file = $hash->{stdout};
	push(@files, $file) if index($file, $job_tmp) == 0;
	$file = $hash->{stderr};
	push(@files, $file) if index($file, $job_tmp) == 0;
    }
    printf STDERR "removing %d output files...\n", scalar @files;;
    unlink(@files);
    my $num_jobs = @ids;
    warn "deleting $num_jobs jobs...\n";
    $dbh->do("delete from $job_table where id in ($ids);");
    $dbh->do("delete from $command_table where id in ($ids);");
    warn "optimizing job table...\n";
    $dbh->do("optimize table $job_table");
}

#
#   do_my_housekeeping($verbosity_level)
#	verbosity 1 = tell what we're doing
#	verbosity 2 = tell but don't do
#
sub do_my_housekeeping {

    my ($verbose) = @_;

    if (!I_am_root()) {
	die "You must be root to do housekeeping";
    }

    &jobs_connect;
    if ($debug || $verbose) {
	chomp(my $date = `date`);
	warn "doing housekeeping on $current_host at $date\n" if $debug;
    }

    my @running = do_select("
	select id, pgid
	from $job_table
	where status in ('running', 'handing off', 'unknown') and running_host = '$current_host'
	    and (unix_timestamp() - unix_timestamp(start_time)) > 20
	order by id;", 1, 1);

    my (@orphans, @ping);
    for my $job (@running) {
	my ($id, $pgid) = split /\t/, $job;
	warn "checking job $id with pgid $pgid\n" if $debug || $verbose;
	warn "sending null signal: kill -0 -$pgid\n" if $debug || $verbose;
	if (system("kill -0 -$pgid 2> /dev/null") != 0) {
	    warn "jobs $id pgid $pgid does not seem to be running on $current_host\n" if $debug || $verbose;
	    my $pgrep = `pgrep -l -g $pgid '.*' | sed 's/^/\t/'`;
	    warn "pgrep -l -g $pgid '.*':\n$pgrep\n" if $debug || $verbose;
	    push(@orphans, $id);
	}
	else {
	    warn "process is running\n" if $debug || $verbose;
	    push(@ping, $id);
	}
    }

    warn "orphans: @orphans\n" if $debug || $verbose;
    warn "running: @ping\n" if $debug || $verbose;
    #
    #   Mark running jobs
    #
    if (@ping) {
	my $ids = join(",", @ping);
	&write_lock;
	my @hashes = job_hashes(@ping);
	warn "old ping times:\n" if $debug || $verbose;
	for my $hash (@hashes) {
	    warn "id $hash->{id} ping time $hash->{ping_time}\n" if $debug || $verbose;
	}
	warn "pinging running jobs: $ids\n" if $debug || $verbose;
	$dbh->do("update $job_table set ping_time = now(), status = 'running' where id in ($ids)") unless $verbose == 2;
	&unlock;
    }

    #
    #   Process is gone, but maybe it finished normally and is being updated,
    #   so only mark jobs as 'failed' that have been orphaned for a while.
    #
    if (@orphans) {
	my $ids = join(",", @orphans);
	&write_lock;
	my @killing = do_select("
	    select id from $job_table where id in ($ids) and $ping_time > 30", 1, 1);
	warn "marking @killing as failed\n" if $debug || $verbose;
	$dbh->do("update $job_table set status = 'failed', end_time = now()
		  where id in ($ids) and $ping_time > 30") unless $verbose == 2;
	&unlock;
    }

    #
    #   Get failed jobs.
    #
    my @failed = do_select("
	select id
	from $job_table
	where status = 'failed' and retries > 0
	order by id;", 1, 1);
    #
    #   Retry failed jobs.
    #
    if (@failed) {
	warn "retrying failed jobs: @failed\n" if $debug || $verbose;
	my $ids = join(",", @failed);
	&write_lock;
	$dbh->do("update $job_table
		  set status = 'waiting',
		      retries = retries - 1
		  where id in ($ids) and $ping_time > 30") unless $verbose == 2;
	&unlock;
    }

    &jobs_disconnect;
}

sub get_my_queues {
    my $fd;
    open($fd, $host_file) || die "can't open hosts file '$host_file'";
    my %hash;
    while (<$fd>) {
	next if /^#/;
	next if /^\s*$/;
	chomp;
	my ($host_patt, $queue, $num_jobs, $priority) = split /\s+/;
	next if	$current_host !~ /^($host_patt)$/;
	next if $hash{$queue} ne '';	# use first match
	# warn "setting queue $queue to $num_jobs\n";
	$hash{$queue} = "$num_jobs\t$priority";
    }
    return %hash;
}

sub get_number_running {
    my ($string) = @_;
    my $count = 0;
    for my $ps (`ps -e -o cmd`) {
	chomp($ps);
	my $len = length($string);
	$ps = substr($ps, 0, $len);
	$count++ if $ps eq $string;
    }
    return $count;
}

sub valid_email {
    my ($email) = @_;
    return $email =~ /^[-\w.]+@[-a-zA-Z0-9.]+$/;
}

sub try_connect {
    my ($host, $port) = @_;
    my $prev_alarm = alarm(10);
    my $prev_sig = $SIG{'ALRM'};
    $SIG{'ALRM'} = 'cancel_connect';
    eval { our $tmp_sock = ::tcp_connect($host, $server_port); };
    $SIG{'ALRM'} = $prev_sig;
    alarm($prev_alarm);
    return $tmp_sock;
}

sub ping_process {
    my ($host, $pgid) = @_;
    if ($host eq $current_host) {
	return (system("kill -0 -$pgid 2> /dev/null") == 0);
    }
    my $sock = try_connect($host, $server_port);
    if (defined $sock) {
	print $sock "ping $pgid\n";
	flush $sock;
	my $status = timed_read($sock, 3, 1);
	close $sock;
	if ($status =~ /yes/) {
	    return 1;
	}
	elsif ($status =~ /no/) {
	    return 0;
	}
    }
    return -1;
}

sub cancel_connect {
}

#
#   do_global_housekeeping($verbosity_level)
#	verbosity 1 = tell what we're doing
#	verbosity 2 = tell but don't do
#
sub do_global_housekeeping {

    my $verbose = shift || $debug;

    if (!I_am_root()) {
	die "You must be root to do housekeeping";
    }

    &jobs_connect;
    if ($verbose) {
	chomp(my $date = `date`);
	warn "doing global housekeeping on $current_host at $date\n";
    }

    my @running = do_select("
	select id, pgid, running_host
	from $job_table
	where status in ('running', 'handing off')
	    and (unix_timestamp() - unix_timestamp(start_time)) > 20
	    and $ping_time > 1200
	order by id;", 1, 1);

    my (@orphans, @ping, %bad_hosts, %good_hosts);
    for my $job (@running) {
	my ($id, $pgid, $host) = split /\t/, $job;
	if ($bad_hosts{$host}) {
	    push(@orphans, $id);
	    next;
	}
	warn "checking running job $id pgid $pgid on host $host\n" if $verbose;
	my $ping = ping_process($host, $pgid);
	if ($ping == -1) {
	    $bad_hosts{$host} = 1;
	    warn "host $host is unreachable\n";
	    push(@orphans, $id);
	}
	elsif ($ping == 0) {
	    $good_hosts{$host} = 1;
	    warn "jobs $id pgid $pgid does not seem to be running on $current_host\n" if $verbose;
	    push(@orphans, $id);
	}
	else {
	    $good_hosts{$host} = 1;
	    push(@ping, $id);
	}
    }

    my @good_hosts = keys %good_hosts;
    my @bad_hosts = keys %bad_hosts;

    warn "bad hosts: @bad_hosts\n" if $verbose;
    warn "orphans: @orphans\n" if $verbose;
    warn "good hosts: @good_hosts\n" if $verbose;
    warn "running: @ping\n" if $verbose;

    &write_lock;
    #
    #   Mark running jobs
    #
    if (@ping) {
	my $ids = join(",", @ping);
	warn "pinging running jobs: $ids\n" if $verbose;
	$dbh->do("update $job_table set ping_time = now() where id in ($ids)") unless $verbose == 2;
    }
    #
    #   Process is gone, so mark it as failed.
    #
    if (@orphans) {
	my $ids = join(",", @orphans);
	warn "marking $ids as failed\n" if $verbose;
	$dbh->do("update $job_table set status = 'failed', end_time = now()
		  where id in ($ids)") unless $verbose == 2;
    }
    #
    #   Get failed jobs.
    #
    my @failed = do_select("
	select id
	from $job_table
	where status = 'failed' and retries > 0
	order by id;", 1, 1);
    #
    #   Retry failed jobs.
    #
    if (@failed) {
	warn "retrying failed jobs: @failed\n" if $verbose;
	my $ids = join(",", @failed);
	$dbh->do("
	    update $job_table
	    set status = 'waiting', retries = retries - 1
	    where id in ($ids) and $ping_time > 30") unless $verbose == 2;
    }
    &unlock;

    &jobs_disconnect;
}

sub kill_jobs {
    my (@ids) = @_;
    return 0 if @ids == 0;
    my %hosts;

    my @pgids;
    for my $id (@ids) {
	my ($status, $pgid, $host, $name) = job_info($id, 'status', 'pgid', 'running_host', 'name');
	next if $pgid == 0 || $host eq '';
	printf "killing pgid %6d on host %-7s for job %6d  %s\n",
	    $pgid, $host, $id, $name
	    if $debug || $just_test;
	$hosts{$host} .= "kill $pgid\n";
    }
    for my $host (keys %hosts) {
	warn "my \$sock = tcp_connect($host, $server_port)\n" if $debug;
	my $sock = try_connect($host, $server_port);
	if ($sock ne '') {
	    warn "connected to $host\n" if $debug || $just_test;
	    if ($just_test) {
		warn "not sending '$hosts{$host}' command to host $host\n";
	    }
	    else {
		warn "sending '$hosts{$host}' command to host $host\n" if $debug;
		print $sock "$hosts{$host}\n";
	    }
	    close $sock;
	}
	alarm(0);
    }
    my $ids = join(",", @ids);
    &write_lock;
    #
    # running or paused: add end_time
    #
    my $cmd = "update $job_table set status = 'killed', end_time = now()
	where status in ('running', 'paused') and id in ($ids)";
    if ($just_test) {
	warn "not running command: $cmd\n";
    }
    elsif ($debug) {
	warn "running command: $cmd\n";
    }
    $dbh->do($cmd) unless $just_test;
    #
    # waiting
    #
    $cmd = "update $job_table set status = 'killed'
	where status in ('waiting') and id in ($ids)";
    if ($just_test) {
	warn "not running command: $cmd\n";
    }
    elsif ($debug) {
	warn "running command: $cmd\n";
    }
    $dbh->do($cmd) unless $just_test;
    &unlock;
}

1;
