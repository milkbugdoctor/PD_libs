#!/usr/bin/perl
use warnings;
use Cwd;
$tempdir = getcwd;

print "USAGE: SNP_from_reads <sample_names> <reference_genome> <no. of processors for bowtie> <sample_suffix>\n Tab delimited file Column 1=bam_files_with_raw_reads column2= output_prefix\n";
system ("module load jdk") || die "Cant load module jdk";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified\n";
if ($ARGV[1]){} else {die "Reference Genome not specified\n";}
if ($ARGV[2]){} else {die "Number of Processors not specified\n";}
if ($ARGV[3]){} else {die "Sample suffix not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);

#print "Building Indexes for reference genome \n";
#system ("bowtie2-build $ARGV[1] $ARGV[1]");

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[2]\n";

                         #print  "bowtie2 --mm -p $ARGV[2] -x $ARGV[1]  -1 $names[0] -2 $names[1] --very-sensitive-local -S $names[2].sam --un-conc $names[2]_R%.unmapped\n";
                         #system ("bowtie2 --mm -p $ARGV[2] -x $ARGV[1]  -1 $names[0] -2 $names[1] --very-sensitive-local -S $names[2].sam --un-conc $names[2]_R%.unmapped");

                         #print "samtools view -@ $ARGV[2] -S -b $names[2].sam >$names[2].bam \n";
                         #system ("samtools view -@ $ARGV[2] -S -b $names[2].sam >$names[2].bam");

                         #print " samtools sort $names[2].bam -o $names[2]_sorted.bam -@ $ARGV[2]\n";
                         #system ("samtools sort $names[2].bam -o $names[2]_sorted.bam -T $names[2] -O bam -@ $ARGV[2]");

                         #system ("java -jar /sc/kzd/home/desaip18/soft/picard/build/libs/picard.jar AddOrReplaceReadGroups I=$names[2]_sorted.bam O=$names[2]_rg.bam SO=coordinate RGID=$names[2] RGLB=$names[2] RGPL=ILLUMINA RGPU=NextSeq RGSM=$names[2]"); ####Add read groups
                         
                         #print "Removing duplicate reads using Picard Tools\n";
                         #system ("java -Xmx2g -jar /sc/kzd/home/desaip18/soft/picard/build/libs/picard.jar  MarkDuplicates INPUT=$names[2]_rg.bam OUTPUT=$names[2]_nodup.bam REMOVE_DUPLICATES=true M=$names[2]_nodup.metrics ASSUME_SORTED=true, TMP_DIR=$tempdir");
												
												 #print "java -jar ~/soft/picard/build/libs/picard.jar CollectWgsMetricsWithNonZeroCoverage I=$names[2]_nodup.bam O=$names[2]_metrics.tab CHART=$names[2]_nodup.pdf   R=$ARGV[1]  INCLUDE_BQ_HISTOGRAM=true";
												 #system ("java -jar ~/soft/picard/build/libs/picard.jar CollectWgsMetricsWithNonZeroCoverage I=$names[2]_nodup.bam O=$names[2]_metrics.tab CHART=$names[2]_nodup.pdf   R=$ARGV[1]  INCLUDE_BQ_HISTOGRAM=true");
                         
                         #print "samtools index $names[2]_nodup.bam\n";
                         #system ("samtools index $names[2]_nodup.bam");

                         system ("java -jar ~/soft/GenomeAnalysisTK.jar -T HaplotypeCaller -R $ARGV[1] -I $names[2]_nodup.bam -dontUseSoftClippedBases -stand_call_conf 0 -stand_emit_conf 0 --emitRefConfidence GVCF -mmq 10 -o $names[2].g.vcf");

                         
                         #print   "java -jar ~/soft/BAMStats-1.25/BAMStats-1.25.jar -v simple -i $names[2]_nodup.bam -o $names[2]_nodup.coverage\n";
                         #system ("java -jar ~/soft/BAMStats-1.25/BAMStats-1.25.jar -v simple -i $names[2]_nodup.bam -o $names[2]_nodup.coverage");

                         #print "samtools idxstats $names[2]_nodup.bam\n";
                         #system ("samtools idxstats $names[2]_nodup.bam > $names[2]_nodup.idxstats");

                         #print "samtools-0.19 mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[2]_nodup.bam > $names[2].bcf\n";
                         #system ( "samtools-0.19 mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[2]_nodup.bam > $names[2].bcf");

                         #print "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[2]_nodup.bam > $names[2].bcf\n";
                         #system ( "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[2]_nodup.bam > $names[2].bcf");

                         #print  "bcftools view -cg $names[2].bcf  | awk '\$6>=60'| vcfutils.pl vcf2fq >  $names[2]_$ARGV[3].fq\n";
                         #system ("~/soft/samtools-0.1.19/bcftools/bcftools view -cg $names[2].bcf  | awk '\$6>=60'| vcfutils.pl vcf2fq >  $names[2]_$ARGV[3].fq");

                         #print " seqtk seq -A $names[2]_$ARGV[3].fq  |sed 's/>/>$names[2]|/' > $names[2]_$ARGV[3].fasta\n";
                         #system ("seqtk seq -A $names[2]_$ARGV[3].fq |sed 's/>/>$names[2]|/' > $names[2]_$ARGV[3].fasta");

                         #print "sed 3,4d $names[2]_$ARGV[3].fasta -i\n";
                         #system ("sed 3,4d $names[2]_$ARGV[3].fasta -i ");





                         #print"python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ";
                         #system("python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ");


                         unlink "$names[2].sam";
                         #unlink "$names[2].bam";
                         #unlink "$names[2]_sorted.bam";
                        #unlink "$names[2]_$ARGV[1].fq";
                         #unlink "$names[2]_1";
                         #unlink "$names[2]_2";
                         }
print "ALL DONE\n";



