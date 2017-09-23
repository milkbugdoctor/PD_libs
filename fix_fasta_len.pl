#!/usr/bin/perl
use warnings;
print "USAGE: fix_fasta_len.pl <list of files> <desired_length>\n the list of files should be a tab delimited file with file name in the first column \n";

open ("filenames", "$ARGV[0]") || die "Please specify a list of fasta file\n";

if ($ARGV[1]){} else {die "Desired length not specified\n";}

@names1=<filenames>;
grep(s/\s+$//,@names1);

foreach $names1(@names1){
                         @names=split (/\t/, $names1);
                         #print "opening $names[0]\n";
                         open ("fasta" , "$names[0]") || die " Error opening $names[0]. Make sure the name is correct and the file exists\n";
                         system ("fasta2tabbed 1 2 $names[0] | sed 1d > $names[0].tab");
                         open ("tabbed", "$names[0].tab") || die " You proposed I disposed. Something went wrong at line 13 \n";
                         @tabbed1=<tabbed>; # 1 element in the array @tabbed1;
                         grep(s/\s+$//,@tabbed1);
                         @tabbed=split (/\t/, $tabbed1[0]); # 2 elements in the array @tabbed
                         @bases= split (//, $tabbed[1]); # array @bases have all the bases
                         %fasta;
                         $i=1;
                         foreach (@bases){
                         	 	  $fasta{$i}=$_;
                                          $i++;
                                          }
                         $z=$ARGV[1]-$i;
                         if ($z+1 < 0) { die "Length of $names1 $i is greater than $ARGV[1]\n";}

                         $p=$ARGV[1];
                         $q=$i-1;
                         print "$q bases in $names[0], need to add $z+1  n's at the end \n";
                         for ($x=$i; $x<=$p; $x++){
                                                           #print "$x";
                                                           $fasta{$x}='n';
                                                           }
                         unlink "$names[0].tab";
                         open (output , ">$names[0]");
                         print output ">$tabbed[0]\n";
                         for ($y=1; $y<=$p; $y++){
                                                        #print "$y";
                                                        print output "$fasta{$y}" ;
                                                        }
                          print output "\n";                              
                         }








