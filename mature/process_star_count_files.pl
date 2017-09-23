#!/usr/bin/perl
open ("names", $ARGV[0]) || die "list of files not specified \n";

@names=<names>;
grep(s/\s+$//,@names);
           
foreach $names(@names){
												open ("input", $names) || die " Cant open $names\n";
												open ("output", ">$names.stranded") || die " Need permission to write in this directory\n";
												print output "Gene\t$names\n";
												while (<input>){
																				@input1=split (/\t/,$_);
																				grep(s/\s+$//, @input1);
																				print output "$input1[0]\t$input1[3]\n";
																			}
											}