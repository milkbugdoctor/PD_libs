#!/usr/bin/perl
#use warnings;
print "USAGE: STAR_qsub.pl <sample_names> <number of cores> <Star_ref_directory> <rsem_ref_directory>  \nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Star ref dir not specified\n";}
if ($ARGV[3]){}else { die "RSEM ref dir not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
			 										@names=split(/\t/, $sample);
			 										#print  "qsub -pe threaded $ARGV[1] -e $names[2].err -cwd -V -b y ~/soft/STAR-STAR_2.5.0a/bin/Linux_x86_64/STAR  --runThreadN $ARGV[1] --genomeDir $ARGV[2] --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --quantMode GeneCounts TranscriptomeSAM --twopassMode Basic --outFilterScoreMinOverLread 0.66 --outFilterMatchNminOverLread  0.51  --outFilterType BySJout --outFilterMultimapNmax 20 --alignSJoverhangMin 5 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --readFilesIn $names[0] $names[1] --outFileNamePrefix $names[2]  genomeLoad=LoadAndRemove --outReadsUnmapped Fastx\n";
			 										system ("qsub -pe threaded $ARGV[1] -e $names[2].err -cwd -V -b y STAR  --runThreadN $ARGV[1] --genomeDir $ARGV[2] --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --quantMode GeneCounts TranscriptomeSAM --twopassMode Basic --outFilterScoreMinOverLread 0.66 --outFilterMatchNminOverLread  0.66 --outFilterType BySJout --outFilterMultimapNmax 1000 --alignSJoverhangMin 5 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --readFilesIn $names[0] $names[1] --outFileNamePrefix $names[2]  genomeLoad=LoadAndRemove --outReadsUnmapped Fastx --outMultimapperOrder Random --outSAMprimaryFlag AllBestScore ");
			 										#system ("qsub -pe threaded $ARGV[1] -e $names[2].err -cwd -V -b y STAR  --runThreadN $ARGV[1] --genomeDir $ARGV[2] --readFilesCommand gunzip -c --outSAMtype BAM SortedByCoordinate --twopassMode Basic --outFilterScoreMinOverLread 0.66 --outFilterMatchNminOverLread  0.51 --outFilterType BySJout --outFilterMultimapNmax 1000 --alignSJoverhangMin 5 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --readFilesIn $names[0] $names[1] --outFileNamePrefix $names[2]");
													#system ("qsub -pe threaded $ARGV[1] -e $names[2].err -cwd -V -b y rsem-calculate-expression -p $ARGV[1] --alignments $names[2]Aligned.toTranscriptome.out.bam $ARGV[3] $names[2]");                         
                        }                


