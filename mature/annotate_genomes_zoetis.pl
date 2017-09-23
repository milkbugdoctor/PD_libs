#!/usr/bin/perl
#use warnings;
print "USAGE: annotate_genomes_zoetis.pl <sample_names>  \nSample_names = Tab delimited file\nColumn 1= Fasta File\nColumn 2= Genome ID\nColumn 3= Scientific Name\ncolumn 4= Domain\nColumn 5= Genetic-code\nColumn 6= NCBI Taxon ID\nColumn 7= Source\nColumn 8= Source ID\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

system ("source /sc/kzd/app/x86_64/p3/20161201/deployment/user-env.sh");
system ("export P3=/sc/kzd/app/x86_64/p3");
system ("export DEP=$P3/20161201/deployment");


@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "processing $names[1]\n";
													$datestring = localtime();
													print   "$datestring rast-create-genome -o $names[1].gto --genome-id $names[1] --scientific-name \"$names[2]\" --domain $names[3] --genetic-code $names[4] --ncbi-taxonomy-id $names[5] --source $names[6] --source-id $names[7] --contigs $names[0]\n";
													
													system ("rast-create-genome -o $names[1].gto --genome-id $names[1] --scientific-name \"$names[2]\" --domain $names[3] --genetic-code $names[4] --ncbi-taxonomy-id $names[5] --source $names[6] --source-id $names[7] --contigs $names[0]");
													$datestring = localtime();
													print "$datestring\tcreated genome type object and now annotating the genome\n";
													system ("rast-process-genome -i $names[1].gto -o $names[1].gto.processed");
													$datestring = localtime();
													print ("$datestring\tPredictiding Phages\n");
													system ("rast-call-features-prophage-phispy -i $names[1].gto.processed -o $names[1].gto.processed.phage");
													$datestring = localtime();
													print ("$datestring\tExporting files\n");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.features.tab patric_features");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.faa protein_fasta");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.ffn feature_dna");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.sp.tab patric_specialty_genes");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.gbk genbank");
													system ("rast-export-genome -i $names[1].gto.processed.phage  -o $names[1].patric.gff gff");
													
													
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.features.tab patric_features");
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.faa protein_fasta");
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.ffn feature_dna");
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.sp.tab patric_specialty_genes");
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.gbk genbank");
													#system ("rast-export-genome -i $names[1].gto.processed  -o $names[1].patric.gff gff");
													
													$datestring = localtime();
													print ("$datestring\tDone !!!\n");
													
												}