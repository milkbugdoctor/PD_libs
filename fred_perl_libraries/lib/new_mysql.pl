#!/usr/local/bin/perl

use IPC::Open2;
use Net::MySQL;

package mysql;

my $mysql;

# Usage:
#
# mysql'connect(
#        hostname => 'db',
#        user     => 'user',
#        password => 'pass',
#        database => 'db'
# );
sub connect {
	$mysql = Net::MySQL->new(@_) || die "Net::MySQL->new(@_)";
}

#
# do mysql query
#
sub query {
    my ($query, $ignore_error) = @_;
    my @rows;
    my $record_set = query_iterator(@_);
    if (defined($record_set)) {
	while (my $record = $record_set->each) {
	    push(@rows, join("\t", @$record));
	}
    }
    return @rows;
}

sub query_iterator {
    my ($query, $ignore_error) = @_;
    $mysql->query($query);
    if ($mysql->is_error()) {
	my $err = $mysql->get_error_message;
	if ($ignore_error) {
	    warn "mysql->query(@_) : $err" if ! ($err =~ /Duplicate entry/);
	}
	else {
	    die "mysql->query(@_) : $err";
	}
    }
    return undef if ! $mysql->has_selected_record();
    return $mysql->create_record_iterator;
}

1;
