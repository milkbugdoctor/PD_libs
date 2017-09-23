#!/usr/bin/perl
#use warnings;
print " Usage: perl phyletic_pattern.pl <genome_Ids> <Sorted_FastOrtho_output> <output_filename>\n Both files should be tab demilited text files\n";

open (names, $ARGV[0]) || die " No genome_IDs specified\n";
@names=<names>;
grep(s/\s+$//, @names);
print "Read in the genome IDs\n" ;

open (ortho, $ARGV[1]) || die " No FastOrtho_output specified\n";
@ortho=<ortho>;
$z=@ortho;
grep(s/\s+$//, @ortho);
print "Read in the FastOrtho output\n";

open (output, ">$ARGV[2]") || die "No output filename specified\n";

$a=@names;
print "There are total $a genome IDs and $z gene families\n";
$b=$a-1;
print output "Gene_family\t$names[0]\t";
$i=1;
while ($i<$b){
      		print output "$names[$i]\t";
                $i++;
      		#print "value of i is $i\n";
                }
print output "$names[$b]\n";
print "Printed the header rows to the output file \n";

foreach $ortho(@ortho){
			@ortho_1=split(/\t/, $ortho);
                        $d=0;
                        foreach $names(@names){
                                                @count=grep /$names/, @ortho_1;
                                                $c=@count;
                                                if ($d==0){ print output "$ortho_1[0]\t$c\t";}
                                                if ($d>0 & $d<$b){print output "$c\t";}
                                                if ($d==$b){ print output "$c\n";}
                                                $d=$d+1;
                                                }
                        }



