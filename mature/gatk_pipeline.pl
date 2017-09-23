#!/usr/bin/perl
#use warnings;
print "USAGE: gatk_qsub.pl <sample_names> <number of cores> <reference>  \nSample_names = Tab delimited file Column 1=Star output, column2=read group, column 3=library\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Reference database not specified\n";}




@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													system ("java -jar ~/soft/picard-tools-1.130/picard.jar AddOrReplaceReadGroups I=$names[0] O=$names[1]_rg.bam SO=coordinate RGID=$names[1] RGLB=$names[2] RGPL=ILLUMINA RGPU=NextSeq RGSM=$names[1]"); ####Add read groups
													system ("java -jar ~/soft/picard-tools-1.130/picard.jar MarkDuplicates I=$names[1]_rg.bam O=$names[1].dedupped.bam CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT M=$names[1].dedupped.metrics");######### Mark Duplicates
													system ("java -jar ~/soft/GenomeAnalysisTK.jar -T SplitNCigarReads -R $ARGV[2]  -I $names[1].dedupped.bam -o $names[1].split.bam  -rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 -U ALLOW_N_CIGAR_READS"); ### Split reads mapped across introns
													system ("java -jar ~/soft/GenomeAnalysisTK.jar -T HaplotypeCaller -R $ARGV[2] -I $names[1].split.bam -dontUseSoftClippedBases -stand_call_conf 0 -stand_emit_conf 0 --emitRefConfidence GVCF -mmq 10 -o $names[1].g.vcf"); ######Call variants
													#system ("java -jar ~/soft/GenomeAnalysisTK.jar -T HaplotypeCaller -R $ARGV[2] -I $names[1].dedupped.bam -dontUseSoftClippedBases -stand_call_conf 0 -stand_emit_conf 0 --emitRefConfidence GVCF -mmq 10 -o $names[1].g.vcf"); ######Call variants
												}
	