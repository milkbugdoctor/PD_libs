
require 'fasta.pl';

sub get_pred {
    my ($seq, $min, $max) = @_;

    my $tmp = "/tmp/input.$$";
    open(TMP, ">$tmp") || die "$tmp: $!";
    print_wrapped(TMP, $seq);
    close TMP;
    my $stuff = `cd /usr/local/www/TMPred; tmpred -par=matrix.tab -$min -$max -def -in=$tmp -out=/dev/stdout`;
    unlink $tmp;

    if ($stuff =~ /^----->.*\n\s*(.*)/m) {
	return $1;
    }
    elsif ($stuff =~ /probably no transmembrane protein - no possible model found/) {
	return "none found";
    }
    else {
	die "TMPRED error! [$stuff]\n";
    }
}

1;
