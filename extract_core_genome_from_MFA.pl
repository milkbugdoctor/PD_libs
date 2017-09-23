#!/usr/bin/perl
use Cwd;
#use warnings;


print "USAGE extract_coding_regions.pl <coding_coordinates> <alignmnet_file> <output_file>\n";

open ("cor", $ARGV[0])|| die " No corordinate file specified \n";
@cor=<cor>;
grep(s/\s+$//,@cor);
$a=@cor;


open ("output", ">$ARGV[2]") || die "No output file specified \n";
system (" fasta2tabbed 1 2 $ARGV[1] > $ARGV[1].tab");
system (" sed 1d -i $ARGV[1].tab");
open ("seq", "$ARGV[1].tab")|| die "something went wrong at line 17 of the code \n" ;

while (<seq>){


                        @seq=split(/\t/,$_); # array had 2 elements; first element is the seq name, second element has the sequence
                        print "Doing $seq[0] \n";
                        @seq2=split(//,$seq[1]);
                        grep(s/\s+$//, @seq2);
                        #$b=@seq2;
                        #print "$b\n";
                        $i=0;
                        print output ">$seq[0]\n";
                        foreach $cor(@cor){
                                            @cor1=split(/\t/,$cor);
                                            $c=$cor1[0]-1;
                                            $d=$cor1[1]-1;
                                            #print "$c..$d\n";
                                            $i++;
                                            if ($i<$a){

                                                        			for ($x=$c; $x<=$d; $x++){ print output "$seq2[$x]";}


                                                                             }

                                            if ($i eq $a){
                                                        for ($x=$c; $x<=$d; $x++){ print output "$seq2[$x]\n";}
                                                         }
                                             }
                     }
                        unlink "$ARGV[1].tab";




