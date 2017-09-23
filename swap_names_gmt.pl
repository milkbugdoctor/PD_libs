#!/usr/bin/perl
#use warnings;
print "USAGE: swap_names.pl <input_file> <key_file> <output_file> \n Key file is a tab delimilited file where the first column has the text to be changed and the second column has the text that to be changed with\n";
open (key, "$ARGV[1]")|| die "No key specified";
@key=<key>;
grep(s/\s+$//, @key);

open (input, "$ARGV[0]")|| die "No input file specified\n";
open (output, ">$ARGV[2]")|| die "No output file specified";

%keys;
foreach $key(@key){
                   @string=split(/\t/,$key);
				   $keys{$string[0]}=$string[1];
				   }

while(<input>)  {
		$a=$_;
        @names=split(/\t/,$a);
		grep(s/\s+$//, @names);
		$x=@names;
		$z=$x-1;
		
        for ($y=0; $y<$z; $y++){
								
								if (exists $keys{$names[$y]}){
								                             #print "$names[$y] to $keys{$names[$y]} \n";
															 grep (s/$names[$y]\b/$keys{$names[$y]}/, $names[$y]);
								                              print output "$names[$y]\t";
															  }
														else{
															 print output "$names[$y]\t";
															 }
															 
                                }
                
				
				
								if (exists $keys{$names[$z]}){
								                             grep (s/$names[$z]\b/$keys{$names[$z]}/, $names[$z]);
								                              print output "$names[$z]\n";
															  }
														else{
															 print output "$names[$z]\n";
															 }			
				
				
				
				
				
				
				}
				
				



