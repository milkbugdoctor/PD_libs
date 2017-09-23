#!/usr/bin/perl
print "USAGE: gatk_qsub.pl <sample_names> <number of cores> <reference>  \nSample_names = Tab delimited file Column 1=Star output, column2=read group, column 3=library\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Reference database not specified\n";}




@sample=<sample>;
grep(s/\s+$//, @sample);

$i=1;

foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													print   "qsub -b y -pe threaded $ARGV[1]  -cwd -V -e $names[1].err -o $names[1].log  ~/UCI_scripts/mature/gatk_pipeline.pl temp_$i $ARGV[1] $ARGV[2]\n";
													system ("qsub -b y -pe threaded $ARGV[1]  -cwd -V -e $names[1].err -o $names[1].log  ~/UCI_scripts/mature/gatk_pipeline.pl temp_$i $ARGV[1] $ARGV[2]");
													$i=$i+1;
												}
print "All Done\n";
