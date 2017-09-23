#!/usr/bin/perl
#use warnings;
print "USAGE: annotate_genomes_zoetis_qsub.pl <sample_names>  \nSample_names = Tab delimited file\nColumn 1= Fasta File\nColumn 2= Genome ID\nColumn 3= Scientific Name\ncolumn 4= Domain\nColumn 5= Genetic-code\nColumn 6= NCBI Taxon ID\nColumn 7= Source\nColumn 8= Source ID\n";
print "Please make sure the file is formated exactly as specified above\nThe script doesnt check for formatting errors\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

@sample=<sample>;
grep(s/\s+$//, @sample);
$i=1;

#system ("source /sc/kzd/app/x86_64/p3/20161201/deployment/user-env.sh");
#system ("export P3=/sc/kzd/app/x86_64/p3");
#system ("export DEP=$P3/20161201/deployment");

foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													print "/sc/kzd/home/desaip18/UCI_scripts/mature/annotate_genomes_zoetis.pl temp_$i";
													system("qsub -b y -cwd -V -l rast=1 -e $names[1].err -o $names[1].log /sc/kzd/home/desaip18/UCI_scripts/mature/annotate_genomes_zoetis.pl temp_$i");
													
													$i=$i+1;
												}
												$y=$i-1;
												
		print "$y jobs submitted for annotation\n";