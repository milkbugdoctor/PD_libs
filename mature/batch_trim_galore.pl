#!/usr/bin/perl
#use warnings;
print "USAGE: batch_trim_galore.pl <File with read names> <quality_score_for_trimming> <Read1 5 prime trimming> <Read2 5 prime trimming> <output directory> \nThis is a tab delimited file where column 1 is the read1 file and column 2 is the read2 file \n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[4]){} else {die "Output Directory not specified\n";}

print "Following are the parameters being used \nInput_file=$ARGV[0]\nQuality score for trimming=$ARGV[1]\n5 Prime bases trimmed read1=$ARGV[2]\n5 prime bases trimmed read2=$ARGV[3]\noutput Dir=$ARGV[4]\n";

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print "Processing $names[1]\n";
                         print   "trim_galore --fastqc --stringency 3 --output_dir $ARGV[4] --paired --trim1  --quality $ARGV[1] --clip_R1 $ARGV[2] --clip_R2 $ARGV[2] $names[0] $names[1]\n";
                         system ("trim_galore --fastqc --stringency 3 --output_dir $ARGV[4] --paired --trim1  --quality $ARGV[1] --clip_R1 $ARGV[2] --clip_R2 $ARGV[2] $names[0] $names[1]");

                         } 
print "All Done \n Have a nice day\n";                         