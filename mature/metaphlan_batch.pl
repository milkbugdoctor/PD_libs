#!/usr/bin/perl
use warnings;
#use Cwd;

#my $dir=getcwd;

print "USAGE: metaphlan_batch.pl <sample_names> <number of cores>\n Tab delimited file Column 1=Fastq_file_name column 2= output_prefix\n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);



foreach $sample(@sample){
			 @names=split(/\t/, $sample);
                         print " Processing $names[2]\n";
						 
						 #print " metaphlan -t rel_ab  --tax_lev 'a' --bowtie2db ~/soft/nsegata-metaphlan-2f1b17a1f4e9/bowtie2db/mpa  --bt2_ps  very-sensitive-local --bowtie2out $names[1].sam --nproc $ARGV[1]  $names[0] $names[1].metaphlan.tab";
						 #system ("metaphlan -t rel_ab  --tax_lev 'a' --bowtie2db ~/soft/nsegata-metaphlan-2f1b17a1f4e9/bowtie2db/mpa  --bt2_ps  very-sensitive-local --bowtie2out $names[1].sam --nproc $ARGV[1]  $names[0] $names[1].metaphlan.tab ");
						 
						 #print " metaphlan -t rel_ab  --tax_lev 's'  --nproc $ARGV[1]  $names[0].sam $names[1].metaphlan_species.tab\n";
						 #system(" metaphlan -t rel_ab  --tax_lev 's'  --nproc $ARGV[1]  $names[1].sam $names[1].metaphlan_species.tab");

						  #print " metaphlan -t marker_ab_table  --tax_lev 's'  --nproc $ARGV[1]  $names[1].sam $names[1].metaphlan_markers.tab\n";
						 #system(" metaphlan -t marker_ab_table  --tax_lev 's'  --nproc $ARGV[1]  $names[1].sam $names[1].metaphlan_markers.tab");

						 #print " metaphlan -t rel_ab  --tax_lev 'a'  --nproc $ARGV[1]  -biom $names[1].biom  $names[1].sam $names[1].metaphlan_markers.tab\n";
						 #system(" metaphlan -t rel_ab  --tax_lev 'a'  --nproc $ARGV[1] -biom $names[1].biom  $names[1].sam $names[1].metaphlan_markers.tab");


						 print "   qsub -b y -cwd -V   -pe threaded $ARGV[1] -e $names[2].err metaphlan2 $names[0],$names[1] --input_type multifastq -t rel_ab  --tax_lev 'a' --bowtie2db /sc/kzd/home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200   --mpa_pkl /sc/kzd/home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200.pkl  --bt2_ps  very-sensitive-local --min_alignment_len 50 --bowtie2out $names[2].sam --nproc $ARGV[1] --biom $names[2].biom    -o  $names[2].metaphlan.tab \n";
						 system (" qsub -b y -cwd -V   -pe threaded $ARGV[1] -e $names[2].err metaphlan2 $names[0],$names[1] --input_type multifastq -t rel_ab  --tax_lev 'a' --bowtie2db /sc/kzd/home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200   --mpa_pkl /sc/kzd/home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200.pkl  --bt2_ps  very-sensitive-local --min_alignment_len 50 --bowtie2out $names[2].sam --nproc $ARGV[1] --biom $names[2].biom    -o  $names[2].metaphlan.tab");
						 
						 #print "   metaphlan2 $names[1].sam  --input_type bowtie2out  -t rel_ab  --tax_lev 'a' --bowtie2db /home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200   --mpa_pkl /home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200.pkl  --bt2_ps  very-sensitive-local --min_alignment_len 50 --bowtie2out $names[1].sam --nproc $ARGV[1] --biom $names[1].biom    -o  $names[1].metaphlan_counts.tab \n";
						 #system (" metaphlan2 $names[1].sam  --input_type bowtie2out  -t rel_ab  --tax_lev 'a' --bowtie2db /home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200   --mpa_pkl /home/desaip18/soft/biobakery-metaphlan2-4864b9107195/db_v20/mpa_v20_m200.pkl  --bt2_ps  very-sensitive-local --min_alignment_len 50 --bowtie2out $names[1].sam --nproc $ARGV[1] --biom $names[1].biom    -o  $names[1].metaphlan_counts.tab");
						 }