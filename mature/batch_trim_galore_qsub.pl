#!/usr/bin/perl
#use warnings;
print "USAGE: batch_trim_galore.pl <File with read names> <quality_score_for_trimming> <output directory> \nThis is a tab delimited file where column 1 is the read1 file and column 2 is the read2 file \n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[1]){} else {die "Quality cut off from trimming not specified\n";}
if ($ARGV[2]){} else {die "Output Directory not specified\n";}

print "Following are the parameters being used \nInput_file=$ARGV[0]\nQuality score for trimming=$ARGV[1]\n5 Prime bases trimmed read1=$ARGV[2]\n5 prime bases trimmed read2=$ARGV[3]\noutput Dir=$ARGV[4]\n";

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print "Processing $names[1]\n";
                         #print   "qsun -b y -cwd -V trim_galore --fastqc --stringency 3 --output_dir $ARGV[2] --paired   --quality $ARGV[1]   $names[0] $names[1]\n";
                         #system ("qsub -b y -cwd -V trim_galore --fastqc --stringency 3 --output_dir $ARGV[2] --paired   --quality $ARGV[1]   $names[0] $names[1]");
                         system ("qsub -b y -cwd -V trim_galore --fastqc --stringency 3 --output_dir $ARGV[2]    --quality $ARGV[1]   $names[0]")

                         } 
print "All Done \n Have a nice day\n";                         