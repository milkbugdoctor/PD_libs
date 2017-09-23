#!/usr/bin/perl -w

# I think this program originally came from NimbleGen

use IO::Handle; autoflush STDOUT;
use strict;

@ARGV || die "\nUsage: $0 probe-file\n\n";

my @order = split("","ACGT");

foreach my $file (@ARGV) {
    open(IN, $file) or die "Cannot open $!\n";
    while(<IN>) {
	chomp;
	my ($probe, $cycle) = split /\t/;
	my $calc = calculate_cycles($probe);
	print "$probe\t$calc\n";
    }
    
}

sub calculate_cycles {
	# grab the probe sequence from the subroutine call and clean it up
	my $probe = shift;
	$probe = uc $probe;
	$probe =~ tr/AGCT//c;
	my @probe = split("",$probe);

	my $cycles = 0;
	# we know we have to do for every bp in the oligo
	for my $position (0 .. $#probe) {
		# an 'N' means skip 4 cycles.
		if($probe[-1] eq 'N') {
			pop @probe;
			$cycles+=4;
			if(scalar(@probe) == 0) {
				return $cycles;
			}
			next;
		}
		foreach my $base (@order) {
			$cycles++;
			# examine the 3' bp. If it equals the bp we're currently
			# making, pop it off the stack. When we get to the end
			# return the current cycle count
#			print "$cycles\t$base\t$probe[-1]\n";
			if ($probe[-1] eq $base) { pop @probe };
			if (scalar(@probe) == 0) {
				return $cycles;
			}
		}
	}
}

exit(0);
