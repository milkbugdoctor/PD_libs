#!/usr/bin/perl
#use warnings;
print "USAGE: MHC_typing_qsub.pl <sample_names> <seed kmer fasta> <kmer length> \n sample_names=Tab delimited file \nColumn 1=read1, Column 2= read2, Column 3=sample prefix\n";

open ("sample", "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[1]){} else {die "Fasta files for seed kmer not specified\n";}
if ($ARGV[2]){} else {die "Kmer length not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);
$i=1;
foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													system("qsub -b y -cwd -V  -pe threaded 8 -e $names[2].err -o $names[2].log /sc/kzd/home/desaip18/UCI_scripts/mature/MHC_typing.pl temp_$i $ARGV[1] $ARGV[2]");										
													$i=$i+1;
												}
												$y=$i-1;
												
		print "$y jobs submitted\n";