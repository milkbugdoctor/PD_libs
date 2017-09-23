
require 'misc.pl';

sub rc {
    my ($seq) = @_;
    $seq =~ tr/ACGTacgt/TGCAtgca/;
    $seq = scalar reverse $seq;
    return $seq;
}

sub gc_content {
	my ($primer) = @_;
	my @primer = split('', $primer);
	my @GC = grep(/[GC]/, @primer);
	return scalar @GC / scalar @primer;
}

sub unique {
    my (@primers) = @_;
    my %hash;
    for my $p (@primers) { $hash{$p}++; }
    return keys %hash;
}

sub random_primer {
    my ($len) = @_;
    my $primer;
    my @bases = ('A', 'C', 'G', 'T');
    for (my $i = 0; $i < $len; $i++) {
	my $i = int(rand(4));
	$primer .= $bases[$i];
    }
    return $primer;
}

#
#   longest match between 3' of primer and any part of $seq
#
#   only checks forward strand of $seq
#
sub longest_3prime_match {
    my ($primer, $seq) = @_;
    for (my $len = length($primer); $len >= 1; $len--) {
	my $end = substr($primer, -$len);
	$end = reverse $end;
	$end =~ tr/ACGTacgt/TGCATGCA/;
	return $len if $seq =~ /$end/i;
    }
    return 0;
}

#
#   longest match between 3' ends of $primer and $seq
#
#   only checks forward strand of $seq
#
sub longest_end_match {
    my ($primer, $seq) = @_;
    for (my $len = length($primer); $len >= 1; $len--) {
	my $end = substr($primer, -$len);
	my $rc_end = reverse $end;
	$rc_end =~ tr/ACGTacgt/TGCATGCA/;
	my $seq_end = substr($seq, -$len);
	return $len if $seq_end =~ /$rc_end/i;
    }
    return 0;
}

#
#   longest homopolymer repeat (AAA*)
#
sub longest_homopolymer {
    my ($seq) = @_;
    for (my $len = length($seq); $len >= 1; $len--) {
	return $len if $seq =~ /A{$len}/i;
	return $len if $seq =~ /C{$len}/i;
	return $len if $seq =~ /G{$len}/i;
	return $len if $seq =~ /T{$len}/i;
    }
    return 0;
}

sub zzz_try {
    for my $i (1 .. 100) {
	my $seq = random_primer(20);
	printf "$seq AAA %d 3' %d end %d\n", longest_homopolymer("$seq"),
	    longest_3prime_match($seq, $seq),
	    longest_end_match($seq, $seq);
    }
}

1;
