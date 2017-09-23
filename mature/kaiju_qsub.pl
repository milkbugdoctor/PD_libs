#!/usr/bin/perl
#use warnings;
print "USAGE: kaiju_qsub.pl <sample_names> <number of cores>   \nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
#if ($ARGV[2]){}else { die "Kraken database not specified\n";}
#if ($ARGV[3]){}else { die "Number of bases to be clipped not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "Submitting  $names[2]\n";
													system ("qsub -b y -cwd -V -pe threaded $ARGV[1] kaiju -t /sc/kzd/proj/bioinfo/pd_databases/kaiju/nodes.dmp -f /sc/kzd/proj/bioinfo/pd_databases/kaiju/kaiju_db_nr_euk.fmi  -i $names[0] -j $names[1] -z $ARVG[1] -a greedy -e 1 -v -x -o $names[2].kaiju ");
													#system ("qsub -b y -cwd -V -o $names[2].kaiju.repaired cut -f 1,2,4,5,6,7 $names[2].kaiju");
													
												}
													
		