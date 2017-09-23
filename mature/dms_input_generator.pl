#!/usr/bin/perl
#use warnings;
print "USAGE: diamond_batch <sample_names> <diamond_database> <number of cores>\nSample_names = Tab delimited file Column 1=Read1 column 2= sample suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Diamond database not specified\n";}
if ($ARGV[2]){}else { die "Number of cores to use not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													
													
													#print   "~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[1].sam\n";# for single end reads
													#system ("~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[1].sam");
													#print  "sam2fasta.py $ARGV[1].faa $names[1].sam $names[1].aligned.fasta";
													#system("sam2fasta.py $ARGV[1].faa $names[1].sam $names[1].aligned.fasta");
													
													
													#print   "~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[2]_1.sam\n"; #for paired end reads
													#system ("~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[0] -f 101 --unal 0 -o $names[2]_1.sam");
													#system ("~/exe/diamond blastx -p $ARGV[2] -d $ARGV[1] -q $names[1] -f 101 --unal 0 -o $names[2]_2.sam");
													#system("sam2fasta.py $ARGV[1].faa $names[2]_1.sam $names[2]_1.aligned.fasta");
													#system("sam2fasta.py $ARGV[1].faa $names[2]_2.sam $names[2]_2.aligned.fasta");
													#system ("cat $names[2]_1.aligned.fasta $names[2]_2.aligned.fasta > $names[2].aligned.fasta");
													
													
													
													
													#system ("weblogo -f $names[2].aligned.fasta -o $names[2].freq.txt -F logodata  --composition equiprobable -A protein ");													
													#system ("sed '8,280 !d' $names[2].freq.txt | cut -f 2-21 > $names[2].temp");
													#system ("paste sites.temp $ARGV[1].temp $names[2].temp > $names[2].dms.tab");
																										
													open (rowout, ">$names[2].dms.row.tab") || die "Died at line 27\n";
													print rowout "$names[2]\tCounts\n";
													open (matrix, "$names[2].dms.tab") || die "Died at line 28\n";
													@matrix=<matrix>;
													grep(s/\s+$//, @matrix);
													@headerss=split (/\t/, $matrix[0]);
													
												  $b=@headerss;
													@headers=@headerss[2..$b-1];
													
													#foreach (@headers){print "$_\n";}
													
													for ($i=1; $i<@matrix; $i++){
																											@myvaluess=split (/\t/,$matrix[$i]);
																											 $a=@myvaluess;
																											 $mytext="$myvaluess[0]\_$myvaluess[1]";
																											 @myvalues=@myvaluess[2..$a-1];
																											 $j=0;
																											 foreach $headers(@headers){print rowout "$mytext\_$headers\t$myvalues[$j]\n"; $j++; }
																											  
																											}
													
													
													
													
													
													
													
													}
												