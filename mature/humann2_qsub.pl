#!/usr/bin/perl
#use warnings;
print "USAGE: humann2_qsub.pl <sample_names> <number of cores> <output_dir>   \nSample_names = Tab delimited file Column 1=Fastq file 2= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "output dir not specified\n";}
#if ($ARGV[3]){}else { die "Sample suffix not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "Submitting  $names[1]\n";
													system ("qsub -b y -cwd -V -pe threaded $ARGV[1] humann2 --bypass-prescreen --bypass-nucleotide-index --nucleotide-database /sc/kzd/proj/bioinfo/pd_databases/humann_data/chocophlan/bowtie2_index/chocophlan_index -i $names[0] -o $ARGV[2] --threads $ARGV[1] --output-max-decimals 5 --output-basename $names[1]");
													#system ("qsub -b y -cwd -V -o $names[2].kaiju.repaired cut -f 1,2,4,5,6,7 $names[2].kaiju");
													
												}
													
		