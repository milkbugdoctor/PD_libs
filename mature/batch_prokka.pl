#!/usr/bin/perl
use warnings;
print "USAGE: batch_prokka.pl <sample_names> <number of CPUs\n Tab delimited file Column 1=fasta file, column 2=Sample_prefix, column3=Locus TAG Column4=Genus Column5= Species\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified\n";

#if ($ARGV[1]){}else { die "Number Genus not specified\n";}
#if ($ARGV[2]){}else { die "Species not specified\n";}
if ($ARGV[1]){}else { die "Number of CPUs not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[1]\n";
			#~/soft/prokka-1.11/bin/prokka
			 system (" qsub -b y -cwd -V -pe threaded $ARGV[1] -e $names[1].err   prokka $names[0] --outdir $names[1] --prefix $names[1] --addgenes --locustag $names[2]  --genus $names[3] --species $names[4] --strain $names[1] --rfam --gcode 11 --force");

						 
                                              }
print "ALL DONE\n";



