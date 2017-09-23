#!/usr/bin/perl
#use warnings;
print "USAGE: diamond_batch <sample_names> <diamond_database> <number of cores>\nSample_names = Tab delimited file Column 1=Read1 column 2= Read2 column 3= sample name suffix\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Diamond database not specified\n";}
if ($ARGV[2]){}else { die "Number of cores to use not specified\n";}


open (aafile, "$ARGV[1].faa") || die " Cant open $ARGV[1].faa. Make sure you have a file names $ARGV[1].faa\n";
system ("fasta2tabbed 1 2 $ARGV[1].faa | sed 1d > $ARGV[1].faa.tab");
open (aaseq, "$ARGV[1].faa.tab") || die "something went wrong at line 12\n";
open (atemp, ">$ARGV[1].temp") || die "something went wrong at line 13\n";
open (ntemp, ">sites.temp") || die "something went wrong at line 14\n";
open (natemp,">file.temp")|| die "something went wrong at line 15\n";
@myseq=<aaseq>;
grep(s/\s+$//, @myseq);
@x1=split(/\t/, $myseq[0]);
$myaseq=$x1[1];
@residues=split(//, $myaseq);
print ntemp "# POSITION\n";
print atemp "WT\n";
print natemp "WT\n";
$j=1;

foreach (@residues){ 
										print natemp "$j\_$_\n";
										print atemp "$_\n";
										print ntemp "$j\n";
										
										$j++;
										}
									

unlink "$ARGV[1].faa.tab";

@sample=<sample>;
grep(s/\s+$//, @sample);
$i=1;

foreach $sample(@sample){
													@names=split(/\t/, $sample);
													open (output,">temp_$i");
													print output "$sample\n";
													#system ("qsub -b y -cwd -V -e $names[1].err -o $names[1].log -pe threaded $ARGV[2]   dms_input_generator.pl temp_$i $ARGV[1] $ARGV[2]");
													#system (" qsub -b y -cwd -V -e $names[2].err -o $names[2].log dms_diffselection Sample_30.dms.tab $names[2].dms.tab $names[2]-genscript --errorcontrolcounts Sample_29.dms.tab --chartype=aa");
													#system ("sort -k 1 -n -k3 $names[2]-genscriptmutdiffsel.txt -o $names[2]-genscriptmutdiffsel.txt");
													system ("sed 's/,/\t/g' $names[2]-genscriptmutdiffsel.txt -i ");
													system ("sed -e 's/\s\+/_/' -e 's/\s\+/_/' *genscriptmutdiffsel.txt -i");
													
													
													
													
													$i++;
												}
												
													

