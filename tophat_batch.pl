#!/usr/bin/perl
use warnings;
use Cwd;

my $dir=getcwd;

print "USAGE: tophat_batch.pl <sample_names> <reference genome index> <reference GTF file> <reference transcriptome index> <number of cores>\n Tab delimited file Column 1=sample prefix column 2= sample name\n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Reference genome index not specified\n";}
if ($ARGV[2]){}else { die "Reference annotation not specified \n";}
if ($ARGV[3]){}else { die "Reference transcrimtome index not specified\n";}
if ($ARGV[4]){}else { die "Number of cores to use not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);



foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $sample\n";
						 
						 print "tophat2 $ARGV[1] $names[0] $names[2] --output-dir $names[1] -p $ARGV[4] --library-type fr-firststrand --b2-very-sensitive --GTF $ARGV[2] --transcriptome-index $ARGV[3]\n ";
						 system ("tophat2 $ARGV[1] $names[0] $names[2] --output-dir $names[1] -p $ARGV[4] --library-type fr-firststrand --b2-very-sensitive --GTF $ARGV[2] --transcriptome-index $ARGV[3] ");
						 
						 chdir "$dir/tophat_out/" || die "Cant change the directory to tophat_out\n";
						 
						 print "java -Xmx4g -jar /home/pdesai/soft/picard-tools-1.63/picard-tools-1.63/MarkDuplicates.jar INPUT=accepted_hits.bam OUTPUT=accepted_hits_nodup.bam REMOVE_DUPLICATES=true M=accepted_hits_nodup.metrics ASSUME_SORTED=true\n";
						 system("java -Xmx4g -jar /home/pdesai/soft/picard-tools-1.63/picard-tools-1.63/MarkDuplicates.jar INPUT=accepted_hits.bam OUTPUT=accepted_hits_nodup.bam REMOVE_DUPLICATES=true M=accepted_hits_nodup.metrics ASSUME_SORTED=true");
						 
						 print "featureCounts -a $ARGV[2]  accepted_hits_nodup.bam  -O -s 0 -p -o accepted_hits_nodup_unstranded.counts -T $ARGV[4] --primary -d 30 -D 10000 -C \n";
						 system ("featureCounts -a $ARGV[2]  accepted_hits_nodup.bam  -O -s 0 -p -o accepted_hits_nodup_unstranded.counts -T $ARGV[4] --primary -d 30 -D 10000 -C");
						 
						 }