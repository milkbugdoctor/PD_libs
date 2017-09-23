#!/usr/bin/perl
#use warnings;
print "USAGE: gbk2faa_PD_batch <GBK file list> \nSample_names = Tab delimited file Column 1=GBK file list Column= Output faa files \n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified\n";

#if ($ARGV[0]){}else { die "Number of cores to use not specified\n";}
#if ($ARGV[2]){}else { die "Kraken database not specified\n";}
#if ($ARGV[3]){}else { die "Number of bases to be clipped not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "Doing $names[0]\n";
													#system ("gbk2faa_PD.pl $names[0] $names[1]");
													system ("gbk2Fasta.pl -gbk $names[0] -fasta $names[1].fasta");
													
												}
													
		
