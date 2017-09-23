#!/usr/bin/perl
#use warnings;
print "USAGE: download_files.pl <links> \Links = Tab delimited file Column 1=Link to download\n";

open (sample, "$ARGV[0]")|| die "File with links is not specified";


@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
													@names=split(/\t/, $sample);
													print "processing $names[1]\n";
													system ("wget $names[0]");
												}
