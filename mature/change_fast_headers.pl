#!/usr/bin/perl
print "USAGE: change_fasta_headers.pl <input_file> <key_file> <output_file> \n Key file is a tab delimilited file where the first column has the text to be changed and the second column has the text that to be changed with\n";

open (input, "$ARGV[0]")|| die "No input file specified\n";
print "I can read the input file which I hope is fasta\n";

open (key, "$ARGV[1]")|| die "No key specified";
print "I can read the key file which I hope has 2 columns\n";


open (output, ">$ARGV[2]")|| die "No output file specified";


@key=<key>;
grep(s/\s+$//, @key);

%keys;
foreach $key(@key){
                   @string=split(/\t/,$key);
				   $keys{$string[0]}=$string[1];
				   }

print "Read in the Key File\nNow Processing the Data File\n";

while(<input>)  {
									chomp $_;
									$a=$_;
									if($a=~/^>/){
														@mynames=split(/>/,$a);
														
														grep(s/\s+$//, @mynames);
														
														#print "changing $mynames[1] to $keys{$mynames[1]}\n";
														
														if ($keys{$mynames[1]}) {
																											print output ">$keys{$mynames[1]}\n";
																										}		
													  else {print output ">$mynames[1]\n"};
													  }
									else { print output "$a\n";}		
								}		  						
														
									
									