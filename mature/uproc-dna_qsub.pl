#!/usr/bin/perl
#use warnings;
print "USAGE: uproc_qsub.pl <sample_names> <number of cores> <uproc_db> <sample_suffix>   \nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "UPROC database not specified\n";}
if ($ARGV[3]){}else { die "Sample suffix not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "Submitting  $names[2]\n";
													system ("qsub -b y -cwd -V -pe threaded $ARGV[1] uproc-dna -t $ARGV[1] -o $names[2].uproc.$ARGV[3] -s  $ARGV[2] ~/soft/uproc/model/ $names[0] $names[1]");
													#system ("qsub -b y -cwd -V -o $names[2].kaiju.repaired cut -f 1,2,4,5,6,7 $names[2].kaiju");
													
												}
													
		