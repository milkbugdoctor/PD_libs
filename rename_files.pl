#!/usr/bin/perl

use warnings;
print "USAGE: copy_files <names> \n <names> is a tab delimited file where \n column 1= location of file to be copied\n column 2= destination of file to be copied\n";
open (sample, "$ARGV[0]")|| die "File with sample names is not specified";

@sample=<sample>;
grep(s/\s+$//, @sample);

foreach $sample(@sample){
			 @names=split(/\t/, $sample);
       print " Copying $names[0]\n";
       system ("mv $names[0] $names[1]");
                         }
                         