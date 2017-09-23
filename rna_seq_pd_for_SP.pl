#!/usr/bin/perl
use warnings;
print "USAGE: rna_seq_pd.pl <sample_names> <reference_genome> <number of cores> <annotation file in SAF format>\n Tab delimited file Column 1=sample prefix column 2= sample name\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Reference genome not specified\n";}
if ($ARGV[2]){}else { die "Number of cores to use not specified\n";}
#if ($ARGV[3]){}else { die "Annotation file not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);
#print "Building Indexes for reference genome \n";
#system ("bowtie2-build $ARGV[1] $ARGV[1]");

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $sample\n";

                         

                           print   "bowtie2 -p $ARGV[2] -x $ARGV[1]  -1 $names[0] -2 $names[2] --very-sensitive-local  --dovetail -I 20 -X 1000   -S $names[1].sam \n";
                           system ("~/soft/bowtie2-2.2.5/bowtie2 -p $ARGV[2] -x $ARGV[1]  -1 $names[0] -2 $names[2] --very-sensitive-local  --dovetail -I 20 -X 1000   -S $names[1].sam");

                           print "samtools view -S -b $names[1].sam >$names[1].bam \n";
                           system ("~/exe/samtools view -S -b $names[1].sam >$names[1].bam");

                           print " samtools sort $names[1].bam $names[1]_sorted \n";
                           system ("~/exe/samtools sort $names[1].bam $names[1]_sorted");

                         #print "Removing duplicate reads using Picard Tools\n";
                         #system ("java -Xmx4g -jar /home/pdesai/soft/picard-tools-1.63/picard-tools-1.63/MarkDuplicates.jar INPUT=$names[1]_sorted.bam OUTPUT=$names[1]_nodup.bam REMOVE_DUPLICATES=true M=$names[1]_nodup.metrics ASSUME_SORTED=true");

                         print "samtools index $names[1]_nodup.bam\n";
                         #system ("samtools index $names[1]_nodup.bam");
                         system ("~/exe/samtools index $names[1]_sorted.bam");

                         print "samtools idxstats $names[1]_nodup.bam\n";
                         #system ("samtools idxstats $names[1]_nodup.bam >$names[1]_nodup.idxstat ");
                         system ("~/exe/samtools idxstats $names[1]_sorted.bam >$names[1]_sorted.idxstat ");

						print "samtools view -u -f 12 -F 256  $names[1]_sorted.bam > $names[1]_unmapped.bam\n";
						system ("~/exe/samtools view -u -f 12 -F 256  $names[1]_sorted.bam > $names[1]_unmapped.bam");
						
						print "bam2fastq --unaligned -o $names[1]_#.unmapped $names[1]_unmapped.bam\n";
						system ("~/exe/bam2fastq --unaligned -o $names[1]_#.unmapped $names[1]_unmapped.bam");
						
						#print "samstat $names[1]_sorted.bam";
						#system ("samstat $names[1]_sorted.bam");
						
						#print "samstat $names[1]_nodup.bam";
						#system ("samstat $names[1]_nodup.bam");

            #print "featureCounts -a $ARGV[3] -F SAF $names[1]_nodup.bam  -O -s 0 -p -o $names[1]_unstranded.counts";
						#system ("featureCounts -a $ARGV[3] -F SAF $names[1]_nodup.bam  -O -s 0 -p -o $names[1]_unstranded.counts");
						 
                         unlink "$names[1].sam";
                         unlink "$names[1].bam";
                         #unlink "$names[1]_sorted.bam";
                         }
print "ALL DONE\n";



