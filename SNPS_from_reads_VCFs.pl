#!/usr/bin/perl
use warnings;
print "USAGE: SNP_from_reads <sample_names> <reference_genome> <no. of processors for bowtie> <sample_suffix>\n Tab delimited file Column 1=bam_files_with_raw_reads column2= output_prefix\n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){} else {die "Reference Genome not specified\n";}
if ($ARGV[2]){} else {die "Number of Processors not specified\n";}
if ($ARGV[3]){} else {die "Sample suffix not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);

#print "Building Indexes for reference genome \n";
#system ("bowtie2-build $ARGV[1] $ARGV[1]");

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[1]\n";

                         #print  "bowtie2 -p $ARGV[2] -x $ARGV[1]  -1 $names[1] -2 $names[1] --very-sensitive-local -S $names[1].sam  \n";
                         #system ("bowtie2 -p $ARGV[2] -x $ARGV[1]  -1 $names[0] -2 $names[2] --very-sensitive-local -S $names[1].sam ");

                         #print "samtools view -S -b $names[1].sam >$names[1].bam \n";
                         #system ("samtools view -S -b $names[1].sam >$names[1].bam");

                         #print " samtools sort $names[1].bam $names[1]_sorted \n";
                         #system ("samtools sort $names[1].bam $names[1]_sorted");

                         #print "Removing duplicate reads using Picard Tools\n";
                         #system ("java -Xmx2g -jar /home/desaip18/soft/picard-tools-1.130/picard.jar  MarkDuplicates INPUT=$names[1]_sorted.bam OUTPUT=$names[1]_nodup.bam REMOVE_DUPLICATES=true M=$names[1]_nodup.metrics ASSUME_SORTED=true");

                         #print "samtools index $names[1]_nodup.bam\n";
                         #system ("samtools index $names[1]_nodup.bam");

                         #print   "java -jar ~/soft/BAMStats-1.25/BAMStats-1.25.jar -i $names[1]_nodup.bam -o $names[1]_nodup.coverage\n";
                         #system ("java -jar ~/soft/BAMStats-1.25/BAMStats-1.25.jar -i $names[1]_nodup.bam -o $names[1]_nodup.coverage");

                         #print "samtools idxstats $names[1]_nodup.bam\n";
                         #system ("samtools idxstats $names[1]_nodup.bam > $names[1]_nodup.idxstats");

                         print "Adding read groups using Picard Tools\n";
                         system ("java -Xmx2g -jar /home/desaip18/soft/picard-tools-1.130/picard.jar AddOrReplaceReadGroups INPUT=$names[1]_nodup.bam OUTPUT=$names[1]_nodupRG.bam RGID=$names[1] RGLB=$names[1] RGPL=Illumina RGSM=$names[1] RGPU=$names[1]");

                         print "samtools index $names[1]_nodupRG.bam\n";
                         system ("samtools index $names[1]_nodupRG.bam");


                         print ("Detecting variants using GATK \n");
                         system ("java -jar ~/soft/GenomeAnalysisTK.jar -T HaplotypeCaller -R $ARGV[1] -I $names[1]_nodupRG.bam -ploidy 1 -o $names[1]_nodupRG.vcf");
                         system ("bgzip -c $names[1]_nodupRG.vcf > $names[1]_nodupRG.vcf.gz");
                         system ("tabix -p vcf $names[1]_nodupRG.vcf.gz");



                         #print "samtools_old mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf\n";
                         #system ( "samtools_old mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf");

                         #print "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf\n";
                         #system ( "samtools mpileup -q 30 -Q 30 -gBISf $ARGV[1]  $names[1]_nodup.bam > $names[1].bcf");

                         #print  "bcftools_old view -cg $names[1].bcf  | awk '\$6>=20'| vcfutils.pl vcf2fq >  $names[1]_$ARGV[3].fq\n";
                         #system ("bcftools_old view -cg $names[1].bcf  | awk '\$6>=20'| vcfutils.pl vcf2fq >  $names[1]_$ARGV[3].fq");

                         #print " seqtk seq -A $names[1]_$ARGV[3].fq  |sed 's/>/>$names[1]|/' > $names[1]_$ARGV[3].fasta\n";
                         #system ("seqtk seq -A $names[1]_$ARGV[3].fq |sed 's/>/>$names[1]|/' > $names[1]_$ARGV[3].fasta");

                         #print "sed 3,4d $names[1]_$ARGV[3].fasta -i\n";
                         #system ("sed 3,4d $names[1]_$ARGV[3].fasta -i ");





                         #print"python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ";
                         #system("python /home/pdesai/rpkmforgenes.py -o $names[1]_rpkm.tab -i $names[1]_nodup.bam -a 14028S_MMCC_annotations_4.gff -rmnameoverlap  -readcount  -strand -exonnorm ");


                         unlink "$names[1].sam";
                         unlink "$names[1].bam";
                         unlink "$names[1]_sorted.bam";
                        #unlink "$names[1]_$ARGV[1].fq";
                         #unlink "$names[1]_1";
                         #unlink "$names[1]_2";
                         }
print "ALL DONE\n";



