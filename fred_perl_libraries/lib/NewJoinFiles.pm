#!/usr/local/bin/perl

use Columns;
require 'misc.pl';

package NewJoinFiles;

sub new {
    my ($join_type, $header, $left_file, $right_file, @join_keys) = @_;
    if ($join_type !~ /^inner|left$/) {
	die "join_type must be 'inner' or 'left'";
    }
    my $self = {};
    bless $self;
    $self->{'use_headers'} = $header;
    $self->{'join_type'} = $join_type;
    $self->{'join_keys'} = \@join_keys;
    my ($ljk, $rjk) = separate_keys(@join_keys);
    $self->{'left'}{'join_keys'} = $ljk;
    $self->{'right'}{'join_keys'} = $rjk;
    my ($left_sorted) = ::get_tmpfile("/tmp", "joinfiles_left");
    my ($right_sorted) = ::get_tmpfile("/tmp", "joinfiles_right");
    my $h = $header ? "" : "-h";
    ::command("sort_file -c $h @$ljk < $left_file > $left_sorted") == 0 || die "sort_file failed";
    ::command("sort_file -c $h @$rjk < $right_file > $right_sorted") == 0 || die "sort_file failed";
    $self->{'left'}{'sorted'} = $left_sorted;
    $self->{'right'}{'sorted'} = $right_sorted;
    open($self->{'left'}{'fh'}, $left_sorted) || die "can't read $left_sorted";
    open($self->{'right'}{'fh'}, $right_sorted) || die "can't read $right_sorted";
    if ($header) {
	$self->{'left'}{'Columns'} = Columns::new($self->{'left'}{'fh'});
	$self->{'right'}{'Columns'} = Columns::new($self->{'right'}{'fh'});
    }
    return $self;
}

sub nosort {
    my ($join_type, $header, $left_file, $right_file, @join_keys) = @_;
    if ($join_type !~ /^inner|left$/) {
	die "join_type must be 'inner' or 'left'";
    }
    my $self = {};
    bless $self;
    $self->{'use_headers'} = $header;
    $self->{'join_type'} = $join_type;
    $self->{'join_keys'} = \@join_keys;
    my ($ljk, $rjk) = separate_keys(@join_keys);
    $self->{'left'}{'join_keys'} = $ljk;
    $self->{'right'}{'join_keys'} = $rjk;
    open($self->{'left'}{'fh'}, $left_file) || die "can't read $left_file";
    open($self->{'right'}{'fh'}, $right_file) || die "can't read $right_file";
    if ($header) {
	$self->{'left'}{'Columns'} = Columns::new($self->{'left'}{'fh'});
	$self->{'right'}{'Columns'} = Columns::new($self->{'right'}{'fh'});
    }
    return $self;
}

sub separate_keys {
    my (@keys) = @_;
    my (@left, @right);
    for my $key (@keys) {
	if ($key =~ m|^(.*)/(.*)$|) {
	    push(@left, $1);
	    push(@right, $2);
	}
	else {
	    push(@left, $key);
	    push(@right, $key);
	}
    }
    return (\@left, \@right);
}

sub get_Columns {
    my $self = shift;
    my ($which) = @_;
    return $self->{$which}{'Columns'};
}

sub get_row {
    my $self = shift;
    my ($which) = @_;
    my @join_keys = @{$self->{$which}{'join_keys'}};
    my $cols = $self->{$which}{'Columns'};
    my $row = $cols->get_row();
    my $key = join("\000", $row ? $cols->get_col($row, @join_keys) : ());
    $self->{$which}{'key'} = $key;
    $self->{$which}{'row'} = $row;
    return ($row, $key);
}

sub need {
    my $self = shift;
    get_row($self, 'left') if ! defined $self->{'left'}{'key'};
    get_row($self, 'right') if ! defined $self->{'right'}{'key'};
    my $join_type = $self->{'join_type'};
    if ($join_type eq 'inner') {
	return 'done' if $self->{'left'}{'row'} eq '';
	return 'done' if $self->{'right'}{'row'} eq '';
	return 'left' if $self->{'left'}{'key'} lt $self->{'right'}{'key'};
	return 'right' if $self->{'left'}{'key'} gt $self->{'right'}{'key'};
	return 'same';
    }
    elsif ($join_type eq 'left') {
	return 'done'  if $self->{'left'}{'row'} eq '';
	return 'same'  if $self->{'left'}{'key'} eq $self->{'right'}{'key'};
	return 'left'  if $self->{'right'}{'row'} eq '';
	return 'left'  if $self->{'left'}{'key'} lt $self->{'right'}{'key'};
	return 'right' if $self->{'left'}{'key'} gt $self->{'right'}{'key'};
    }
}

sub get_match {
    my $self = shift;
    my (@left_matches, @right_matches);
    my $join_type = $self->{'join_type'};
    while (1) {
	my $need = need($self);
	last if $need eq 'done';
	if ($need eq 'same') {
	    @left_matches = @right_matches = ();
	    my $same = $self->{'left'}{'key'};
	    push(@left_matches, $self->{'left'}{'row'});
	    push(@right_matches, $self->{'right'}{'row'});
	    while (1) {
		my ($row, $key) = get_row($self, 'left');
		last if $row eq '';
		last if $key ne $same;
		push(@left_matches, $row);
	    }
	    while (1) {
		my ($row, $key) = get_row($self, 'right');
		last if $row eq '';
		last if $key ne $same;
		push(@right_matches, $row);
	    }
	    return (\@left_matches, \@right_matches);
	}
	elsif ($join_type eq 'inner') {
	    my ($row, $key) = get_row($self, $need);
	    last if $row eq '';
	}
	elsif ($join_type eq 'left') {
	    if ($need eq 'right') {
		my ($row, $key) = get_row($self, $need);
		next;
	    }
	    # nobody on the right
	    push(@left_matches, $self->{'left'}{'row'});
	    get_row($self, $need);
	    return (\@left_matches, undef);
	}
    }
    return ();
}

sub cleanup { # ZZZ - is there a way to do this automatically?
    my $self = shift;
    unlink($self->{'left'}{'sorted'})  if (-e $self->{'left'}{'sorted'});
    unlink($self->{'right'}{'sorted'}) if (-e $self->{'right'}{'sorted'});
}
