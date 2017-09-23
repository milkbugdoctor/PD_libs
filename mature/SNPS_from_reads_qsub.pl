#!/usr/bin/perl
#use warnings;
print "USAGE: kraken&fiter.pl <sample_names> <Ref Genome> <number of cores> <sample suffix>\nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Sample suffix not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);
$i=1;


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													#print "qsub -b y -cwd -V -e $names[2].err -o $names[2].log  -pe threaded $ARGV[2] SNPS_from_reads.pl temp_$i $ARGV[1] $ARGV[2] $ARGV[3]";
												  system("qsub -b y -cwd -V -e $names[2].err -o $names[2].log  -pe threaded $ARGV[2] SNPS_from_reads.pl temp_$i $ARGV[1] $ARGV[2] $ARGV[3]");
												  #system("qsub -b y -cwd -V -e $names[1].err -o $names[1].log  ~/UCI_scripts/SNPS_from_reads_bam.pl temp_$i $ARGV[1]");
												 
												 
													$i=$i+1;
												}
		print "All Done\n";											