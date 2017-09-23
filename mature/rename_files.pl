#!/usr/bin/perl
#use warnings;
print "USAGE: rename_files.pl <links> \Links = Tab delimited file Column 1=old name column 2= new name\n";

open (sample, "$ARGV[0]")|| die "File with links is not specified";


@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "processing $names[1]\n";
													system ("mv $names[0] $names[1]");
												}
