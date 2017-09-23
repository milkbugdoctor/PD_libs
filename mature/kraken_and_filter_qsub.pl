#!/usr/bin/perl
#use warnings;
print "USAGE: kraken&fiter.pl <sample_names> <number of cores> <kraken_db>  \nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Kraken database not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);
$i=1;


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													print  "qsub -b y -cwd -V -e $names[2].err -o $names[2].log -q ram.q  -pe threaded $ARGV[1] ~/UCI_scripts/mature/kraken_and_filter.pl temp_$i $ARGV[1] $ARGV[2]\n";
													system("qsub -b y -cwd -V -e $names[2].err -o $names[2].log -q ram.q  -pe threaded $ARGV[1] ~/UCI_scripts/mature/kraken_and_filter.pl temp_$i $ARGV[1] $ARGV[2]");
													$i=$i+1;
												}
		print "All Done\n";											