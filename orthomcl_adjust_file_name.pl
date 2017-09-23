#!/usr/bin/perl
use warnings;
use Cwd;
#$dir =getcwd;
#print "The current working directory is $dir \n";
print "USAGE: orthomcl_adjust.pl <file names> <ID Field> \n column 1= file name \n column 2= Taxon code\n";

open (sample, "$ARGV[0]")|| die "File with sample names is not specified";
if ($ARGV[1]){}else { die "Field number not specified\n";}

@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $files(@sample){
			@name=split(/\t/,$files);
                        print "orthomclAdjustFasta $name[1] $name[0] $ARGV[1]\n";
                        system ("orthomclAdjustFasta $name[1] $name[0] $ARGV[1]");
                        }
