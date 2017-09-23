#!/usr/bin/perl
#use warnings;
print "USAGE: batch_a5.pl <sample_names> <number of threads> \nTab delimited file Column 1= read1, Column 2= read2 ,column 3= sample prefix\n";

open ("sample", "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[1]){} else {die "Number of Processors not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[2]\n";
			
			 #system ("qsub -pe threaded $ARGV[1]  -cwd -V -e $names[2].err -b y -q all.q  a5_pipeline.pl --end 5 $names[0] $names[1] $names[2] --metagenome --threads=$ARGV[1]");
			 system ("qsub -pe threaded $ARGV[1]  -cwd -V -e $names[2].err -b y -q all.q  a5_pipeline.pl --end 5 $names[0] $names[1] $names[2]  --threads=$ARGV[1]");
			 #system ("a5_pipeline.pl  $names[0] $names[2] $names[1] --threads=$ARGV[1]");



						 
                        
                         }
print "ALL DONE\n";



