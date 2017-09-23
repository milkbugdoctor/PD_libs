#!/usr/bin/perl
use warnings;
print "USAGE: SNP_from_reads <sample_names> <reference_genome> \n Tab delimited file Column 1=bam_files_with_raw_reads column2= output_prefix\n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
@sample=<sample>;
grep(s/\s+$//, @sample);
print "Building Indexes for reference genome \n";
#system ("bowtie2-build $ARGV[1] $ARGV[1]");

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[1]\n";

                         #print "bam2fastq -o $names[1]# $names[0]\n";
                         #system ("bam2fastq -f -o $names[1]# $names[0]");

                         #print  "bowtie2 -p 4 -x $ARGV[1]  -1 $names[1]_1 -2 $names[1]_2 --very-sensitive-local -S $names[1].sam \n";
                         #system ("bowtie2 -p 4 -x $ARGV[1]  -1 $names[1]_1 -2 $names[1]_2 --very-sensitive-local -S $names[1].sam");
                         #system ("bowtie2 -p 8 -x $ARGV[1]  -1 $names[0] -2 $names[2] --very-sensitive-local -S $names[1].sam");
                         #system ("bowtie2 -p 2 -x $ARGV[1]  -U $names[0] --very-sensitive-local -S $names[1].sam");
                         #print ("bowtie2 -p 2 -x $ARGV[1]  -U $names[0] --very-sensitive-local -S $names[1].sam");

                         #print "samtools view -S -b $names[1].sam >$names[1].bam \n";
                         #system ("samtools view -S -b $names[1].sam >$names[1].bam");

                         #print " samtools sort $names[1].bam $names[1]_sorted \n";
                         #system ("samtools sort $names[1].bam $names[1]_sorted");
													

                         #print "Rrmoving duplicate reads using Picard Tools\n";
                         #system ("java -Xmx2g -jar /home/pdesai/soft/picard-tools-1.63/picard-tools-1.63/MarkDuplicates.jar INPUT=$names[1]_sorted.bam OUTPUT=$names[1]_nodup.bam REMOVE_DUPLICATES=true M=$names[1]_nodup.metrics ASSUME_SORTED=true");

                         #print "samtools index $names[1]_nodup.bam\n";
                         #system ("samtools index $names[1]_nodup.bam");
                         #system ("samtools index $names[1]_sorted.bam");

                         #print "samtools idxstats $names[2]_nodup.bam\n";
                         #system ("samtools idxstats $names[2]_nodup.bam");

                         #print "samtools mpileup -q 30 -Q 30 -uf $ARGV[1]  $names[1]_nodup.bam | bcftools view -cg - | awk '\$6>=30'| vcfutils vcf2fq | sed '/^+/q'|sed 's/@.*/>$names[1]/; s/+//' > $names[1]_LT2.fasta\n";
                         #system ("samtools mpileup -q 30 -Q 30 -uf $ARGV[1]  $names[1]_nodup.bam | bcftools view -cg - | awk '\$6>=30'| vcfutils vcf2fq | sed '/^+/q'|sed 's/@.*/>$names[1]/; s/+//'  > $names[1]_LT2.fasta");

                         print "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf\n";
                         #system ( "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf");
                         system ( "samtools mpileup -q 30 -Q 30 -f $ARGV[1]  $names[1]_sorted.bam > $names[1].txt");
                         
                         

                         #print  "bcftools view -cg $names[1].bcf  | awk '\$6>=60'| vcfutils vcf2fq >  $names[1]_P125109.fq\n";
                         #system ("bcftools view -cg $names[1].bcf  | awk '\$6>=60'| vcfutils vcf2fq >  $names[1]_P125109.fq");

                         #print " seqtk seq -A $names[1]_P125109.fq  |sed 's/>/>$names[1]|/' > $names[1]_P125109.fasta\n";
                         #system ("seqtk seq -A $names[1]_P125109.fq |sed 's/>/>$names[1]|/' > $names[1]_P125109.fasta");

                         #print "sed 3,4d $names[1]_P125109.fasta -i\n";
                         #system ("sed 3,4d $names[1]_P125109.fasta -i ");





                         #print"python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ";
                         #system("python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ");


                         unlink "$names[1].sam";
                         unlink "$names[1].bam";
                         #unlink "$names[1]_sorted.bam";
                         #unlink "$names[1]_1";
                         #unlink "$names[1]_2";
                         }
print "ALL DONE\n";



