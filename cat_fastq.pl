#!/usr/bin/perl
#use warnings;
print "USAGE: cat_fastq.pl <sample_names>\nTab delimited file Column 1= comma separated read1 files, Column 2= comma separated read2 \n";

open ("sample", "$ARGV[0]")|| die "File with sample names is not specified\n";

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
													@names=split(/\t/, $sample);
													@read1=split (/,/, $names[0]);
													@read2=split(/,/, $names[1]);
												  system ("cat $read2[1] $read2[2] >> $read2[0]");
												  system ("cat $read1[1] $read1[2] >> $read1[0]"); 
												  #print "cat $read2[1] $read2[2] >> $read2[0]\n";
												  #print "cat $read1[1] $read1[2] >> $read1[0]\n";
												}
