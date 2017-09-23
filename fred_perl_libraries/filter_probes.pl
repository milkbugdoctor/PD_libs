
require 'do_blat.pl';
require 'misc.pl';

package filter_probes;

my $seq_col = 'PROBE_SEQUENCE';
my $min = 20;
my $min_last = 6;
my @lost;

sub lines {
    open(FOO, $_[0]);
    my @lines = <FOO>;
    close FOO;
    return scalar(@lines);
}

sub 'filter_probes {
    my ($class, $probefile) = @_;

    chomp(my $tm = `cat avg_tm`);
    die "Can't get tm from 'avg_tm' file" if $tm == 0;

    printf "%d lines before do_repeats\n", &lines($probefile);
    return 0 if lines($probefile) < $min;

    @lost = ::cmd("../do_repeats $seq_col '$probefile' 2>&1");

    printf "%d lines before do_tm\n", &lines($probefile);
    return 0 if lines($probefile) < $min;

    push(@lost, ::cmd("../do_tm $tm '$probefile' 2>&1"));

    printf "%d lines before prune_probes\n", &lines($probefile);
    return 0 if lines($probefile) < $min;

    ::command("../prune_probes '$probefile'");

    printf "%d lines before blat\n", &lines($probefile);

    return 0 if lines($probefile) < $min_last;

    return 0 if ! ::do_client_blat($probefile);

    my $lines = lines($probefile);

    printf "$lines final lines\n";

    return ($lines >= $min_last);
}

1;
