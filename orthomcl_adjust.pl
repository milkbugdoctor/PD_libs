#!/usr/bin/perl
use warnings;
use Cwd;
$dir =getcwd;
print "The current working directory is $dir \n";
@files=<$dir/*.faa>;
my $size=@files;
print " I will process $size files\n";
foreach $files(@files){
			@name=split(/\//,$files);
                        $n=@name;
                        $name1=$name[$n-1];
                        @name2=split(/\./,$name1);
                        print "$name2[0] \n";
                        system ("orthomclAdjustFasta $name2[0] $files 1");
                        }
