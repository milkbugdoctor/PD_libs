
package fasta_db;

use Carp qw(confess cluck);
use DBI;

$fasta_host  = 'db';
$fasta_db    = 'fasta';
$fasta_user  = 'flong';
$fasta_pass  = 'jon edward';

my $dbh;
my $counnected = 0;

sub connect {
    return if $connected++ > 0;
    my $dsn = "DBI:mysql:host=$fasta_host";
    ($dbh = DBI->connect($dsn, $fasta_user, $fasta_pass)) || confess "DBI->connect: $!";
    $dbh->do("create database if not exists $fasta_db");
    $dbh->do("use $fasta_db");
}

sub create_table {
    my ($table) = @_;
    $dbh->do("drop table if exists $fasta_db.$table");
    $dbh->do("
    create table $fasta_db.$table (
	id          text not null,
	descr       text not null,
	seq         text not null,
	primary key (id(30)),
	index (descr(80))
    );");
}

sub disconnect {
    if (--$connected <= 0) {
	$dbh->disconnect;
	$connected = 0;
    }
}

sub add {
    my ($table, $id, $desc, $seq) = @_;
    # &write_lock($table);
    my $str = "insert into $fasta_db.$table (id, descr, seq) values (?, ?, ?)";
    my $result = $dbh->do($str, undef, $id, $desc, $seq);
    if (! defined $result) {
	&unlock;
	confess "Failed to add fasta:\n$cmdtext\n";
    }
    # &unlock;
}

##################################################################################

sub fasta_update {
    my ($table, $id, $field, $value) = @_;
    &write_lock($table);
    $dbh->do("update $table set $field = ? where id = $id", undef, $value);
    &unlock;
}

sub get_entry {
    my ($table, $id) = @_;
    my $cmd = "select id, descr, seq from $fasta_db.$table where id = $id";
    &read_lock($table);
    my $sth = $dbh->prepare($cmd);
    $sth->execute() || do {
	&unlock;
	warn "fasta_info: [$cmd] failed: $!\n";
	return '';
    };
    my @row = $sth->fetchrow_array();
    $sth->finish();
    &unlock;
    return @row;
}

sub fasta_status {
    my ($status) = fasta_info($_[0], 'status');
    return $status;
}

sub read_lock {
    my ($fasta_table) = @_;
    $dbh->do("lock tables $fasta_table read;") || confess "can't lock $fasta_table";
}

sub write_lock {
    my ($fasta_table) = @_;
    $dbh->do("lock tables $fasta_table write;") || confess "can't lock $fasta_table";
}

sub lock {
    my ($fasta_table) = @_;
    $dbh->do("lock tables $fasta_table write;") || confess "can't lock $fasta_table";
}

sub unlock {
    my ($fasta_table) = @_;
    $dbh->do("unlock tables;") || cluck "can't unlock $fasta_table";
}

sub do_select {
    my ($query, $die_on_error)  = @_;
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
    unshift(@result, join("\t", @cols)) if @result;
    return @result;
}

1;
