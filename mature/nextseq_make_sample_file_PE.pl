#!/usr/bin/perl

print "nextseq_make_sample_file.pl <directory listing> <sample output prefix>\n";

if($ARGV[0]){} else{die "No input specified\n"};

open ("output",">$ARGV[0].tab") || die "Need Permission to write here\n";

#if($ARGV[1]){} else{die "Need to specify the sample output prefix"};

system ("sed 's/:/\\//g' -i $ARGV[0]");
open ("input", $ARGV[0]) || die "No input \n";

@input=<input>;
grep(s/\s+$//, @input);
  
$a=@input;
for ($i=0; $i<=$a; $i=$i+4)### for 1 file paired end change i to 4
																				{
																				 @samplenames=split (/\//,$input[$i]);
																				 $b=@samplenames;
																				 #print output "$input[$i]$input[$i+1],$input[$i]$input[$i+3],$input[$i]$input[$i+5],$input[$i]$input[$i+7]\t$input[$i]$input[$i+2],$input[$i]$input[$i+4],$input[$i]$input[$i+6],$input[$i]$input[$i+8]\t$ARGV[1]$samplenames[$b-1]\n"; ### for 4 lanes
																				 print output "$input[$i]$input[$i+1]\t$input[$i]$input[$i+2]\n"; #### for 1 file paired end
																				 #print output "$input[$i]$input[$i+1]\n";####for 1 file single end
																				 
																				}