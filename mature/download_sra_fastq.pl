#!/usr/bin/perl
#use warnings;
print "USAGE: download_sra_fastq.pl <links> \Links = Tab delimited file Column 1=SRA run number SRRXXXXXXX \n";

open (sample, "$ARGV[0]")|| die "File with SRA run numbers is not specified";


@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "processing $names[0]\n";
													system ("fastq-dump  --split-files --gzip $names[0]");
												}
