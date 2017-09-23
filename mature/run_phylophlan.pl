#!/usr/bin/perl
use warnings;
print "USAGE: run_phylophlan.pl <project_name> <number of cores>\n";
if ($ARGV[0]){}else { die "project_name not specified\n";}
if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
system ("module load phylophlan");
system ("module load  python/2.7.10");
system ("/sc/kzd/home/desaip18/soft/nsegata-phylophlan-8e2d2ec74872/phylophlan.py --nproc $ARGV[1] $ARGV[0]");

