#!/usr/bin/perl

use IPC::Open2;
use IO::Poll qw(POLLRDNORM POLLWRNORM POLLIN POLLHUP POLLERR);
use Carp;

package mysql;

our $host = "dell3";

package main;

sub query {
	return &mysql_chomp_noheader;
}

sub mysql {
	return &mysql_query(@_);
}

sub mysql_chomp {
	return grep(chomp, &mysql_query(@_));
}

sub mysql_noheader {
	my @results = &mysql(@_);
	return @results[1..$#results];
}

sub mysql_chomp_noheader {
	my @results = &mysql_chomp(@_);
	return @results[1..$#results];
}

#
# do query, keep header and newlines
#
sub mysql_query {
	my ($write_handle, $read_handle);
	my $cmd = "mysql -h $mysql::host";
	(my $pid = open2($read_handle, $write_handle, $cmd)) || die "open2";
	print $write_handle "@_";
	close($write_handle);
	my @result = <$read_handle>;
	waitpid $pid, 0;
	return @result;
}

sub query_output {
	return mysql_output($_[0], 0);
}

#
#	mysql_output($query, $show_header)
#
sub mysql_output {
	my ($write_handle, $read_handle);
	my $cmd = $_[1] ? 'mysql' : 'mysql -N';
	$cmd .= " -h $mysql::host";
	(my $pid = open2($read_handle, $write_handle, $cmd)) || die "open2";
	print $write_handle "$_[0]";
	close($write_handle);
	confess "mysql error in sql [$_[0]]" if was_mysql_error($read_handle);
	return $read_handle;
}

sub was_mysql_error {
    my ($fd) = @_;
    my $poll = new IO::Poll;
    $poll->mask($fd => POLLIN | POLLERR | POLLHUP);
    $poll->poll();
    my $ev = $poll->events($fd);
    my $foo = ($ev & (POLLERR | POLLHUP));
    return $foo;
}

1;
