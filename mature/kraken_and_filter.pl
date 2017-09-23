#!/usr/bin/perl
#use warnings;
print "USAGE: kraken&fiter.pl <sample_names> <number of cores> <kraken_db>   \nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

if ($ARGV[1]){}else { die "Number of cores to use not specified\n";}
if ($ARGV[2]){}else { die "Kraken database not specified\n";}
#if ($ARGV[3]){}else { die "Number of bases to be clipped not specified\n";}



@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "processing $names[2]\n";
													#system ("kraken --db $ARGV[2] --threads $ARGV[1] --fastq-input  --output $names[2].kraken $names[0]"); # uncompressed single end fasta
													#system ("kraken --db $ARGV[2] --threads $ARGV[1] --fastq-input --gzip-compressed --output $names[2].kraken $names[0]"); # for gziped single end
													#system ("kraken --db $ARGV[2] --threads $ARGV[1] --fastq-input --gzip-compressed --paired --output $names[2].kraken  $names[0] $names[1] ");# for gziped paired  end
													system ("kraken --db $ARGV[2] --threads $ARGV[1] --fastq-input --paired --output $names[2].kraken  $names[0] $names[1] "); #### uncompressed paired end
													system ("kraken-filter --db $ARGV[2] --threshold 0.2 $names[2].kraken > $names[2].kraken.filtered");
													#system ("kraken-report --db $ARGV[2] --show-zeros $names[2].kraken.filtered > $names[2].kraken.filtered.report");
													#open ("input","$names[2].kraken.filtered.report" ) || die " Cant open $names\n";
													#open ("output", ">$names[2].kraken.filtered.report.processed") || die " Need permission to write in this directory\n";
													#print output "Taxonomy\t$names[2]\n";
													#while (<input>){
																				#@input1=split (/\t/,$_);
																				#grep(s/\s+$//, @input1);
																				#print output "$input1[0]\t$input1[3]\n";
																			#}
													
													
												}
													
		#--gzip-compressed