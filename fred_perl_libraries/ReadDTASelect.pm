#!/usr/bin/perl

use strict vars;

package ReadDTASelect;

sub new {
    shift if $_[0] eq 'ReadDTASelect';
    my $self = {};
    bless $self;
    my $infile = shift;
    my $fd;
    open($fd, $infile) or die "can't open [$infile]";
    $self->{file} = $infile;
    $self->{fd} = $fd;
    my $line = <$fd>;
    if ($line !~ /^DTASelect (\S+)/) {
	die "$infile is not a DTASelect-filter.txt file";
    }
    else {
	$self->{version} = $1;
    }
    $line = <$fd>;
    $line =~ s/[\r\n]+$//;
    $self->{location} = $line;
    $self->{infile} = $infile;
    while ($line = <$fd>) {
	last if $line =~ /^Unique/;
    }
    return $self;
}

sub next_entry {
    my $self = shift;
    my $fd = $self->{fd};

    my (%Seq, %Pep, %Locus, %Pepid);

    my $first_lines = $self->{first_lines} = $self->{next_lines} || [];
    my $second_lines = $self->{second_lines} = [];
    my $next_lines = $self->{next_lines} = [];

    my $skip;
    while (my $line = <$fd>) {
	$line =~ s/[\n\r]+$//;
	my @line = split /\t/, $line;
	if (@line == 9 && $line[0] && $line[1] =~ /^\d+$/) { # DTASelect-filter
	    my ($gi, $sc, $spc, $cov, $l, $mw, $pi, $vs, $name) = @line;
	    my $seq = '';
	    my @result = ($gi, $seq, $sc, $spc, $cov, $l, $mw, $pi, $name);
	    if (@$second_lines) {
		push(@$next_lines, [ @result ]);
		return ($first_lines, $second_lines);
	    }
	    else {
		push(@$first_lines, [ @result ]);
	    }
	}
	elsif (@line == 9 && $line[0] && $line[1] == 0) { # maggie's format
	    my ($gi, $seq, $sc, $spc, $cov, $l, $mw, $pi, $name) = @line;
	    if (@$second_lines) {
		push(@$next_lines, [ $gi, $seq, $sc, $spc, $cov, $l, $mw, $pi, $name ]);
		return ($first_lines, $second_lines);
	    }
	    else {
		push(@$first_lines, [ $gi, $seq, $sc, $spc, $cov, $l, $mw, $pi, $name ]);
	    }
	}
	elsif (@line == 13 && $line[2] =~ /^\d+\.\d+/) {
	    my ($uniq, $fn, $xc, $delt, $conf, $mass1, $mass2, $intens, $spR,
		    $spScore, $ion, $rddcy, $s) = @line;
	    push(@$second_lines, [ @line ]);
	}
	elsif ($line eq '') {
	    last;
	}
	elsif (@line == 4) {
	    last;
	}
	else {
	    die "unknown line: [$line] [@line] in [$self->{file}]";
	}
    }
    if (@$first_lines && @$second_lines) {
	return ($first_lines, $second_lines);
    }
    else {
	return ();
    }
}

1;
