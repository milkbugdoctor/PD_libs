#!/usr/bin/perl
#use warnings;
print "USAGE: diamond_batch <sample_names> <diamond_database> <number of cores>\nSample_names = Tab delimited file Column 1=Read1 column 2= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Diamond database not specified\n";}
if ($ARGV[2]){}else { die "Number of cores to use not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);
$i=0;


foreach $sample(@sample){
													$i++;
													@names=split(/\t/, $sample);
													print "qsub -b y -cwd -V -e $names[1].err -o $names[1].log -pe threaded $ARGV[2]  ~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[1].sam\n";
													system ("qsub -b y -cwd -V -e $names[1].err -o $names[1].log -pe threaded $ARGV[2]  ~/exe/diamond blastx -p $ARGV[2]  -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[1].sam");
													}
													print "$i jobs submitted\n";