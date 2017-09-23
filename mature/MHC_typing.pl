#!/usr/bin/perl
#use warnings;
print "USAGE: MHC_typing.pl <sample_names> <seed kmer fasta> <kmer length> \n sample_names=Tab delimited file \nColumn 1=read1, Column 2= read2, Column 3=sample prefix\n";

open ("sample", "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[1]){} else {die "Fasta files for seed kmer not specified\n";}
if ($ARGV[2]){} else {die "Kmer length not specified\n";}
@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
	                       @names=split(/\t/, $sample);
	                       system ("bbduk.sh in=$names[0] in2=$names[1] outm=$names[2].filter.FQ ref=$ARGV[1] k=$ARGV[2] stats=$names[2].kmer.stats overwrite=true");
	                       system ("a5_pipeline.pl $names[2].filter.FQ $names[2] --metagenome");
	                       
	                       #system ("seqtk seq -r $names[2].filter.FQ > $names[2].filter.FQ2") if -e "$names[2].filter.FQ";
	                       #system ("a5_pipeline.pl $names[2].filter.FQ $names[2].filter.FQ2 $names[2] --metagenome --end=2 --threads=8") if -e "$names[2].filter.FQ" ;
	                     															
	                     }