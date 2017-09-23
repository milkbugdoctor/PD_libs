#!/usr/bin/perl
#use warnings;
open (input, $ARGV[0])||die " No input file specified\n";
@input=<input>;
grep(s/\s+$//, @input);
open (output,">$ARGV[1]")||die " No output file specified\n";
$a=@input;
#$b=$a/2;
#print "value of b is $b\n";
#$i=0;
@input3=split(/\t/,$input[0]);
print output "$input3[0]\t";
for ($i=0;$i<=$a; $i++){
			@input1=split(/\t/,$input[$i]);
			@input2=split(/\t/,$input[$i+1]);
			$j=0;
			if ($input1[0] eq $input2[0]){
											if ($j = 0){
														print output "$input1[0]\t$input1[1]\t";
														$j=1;
														}
											else {print output "$input1[1]\t";}			
                                         		}
                                                        else{print output "$input1[1]\n$input2[0]\t";
														$j=0;
															}
                                                        
                        }
