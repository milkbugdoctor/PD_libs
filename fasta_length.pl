#!/usr/bin/perl
use warnings;
use Cwd;
print "usage fasta_length.pl <output_file>";
open ("output", ">$ARGV[0]")|| die "No output file specified";

$dir =getcwd;
 print "The current working directory is $dir \n";
        @files=<$dir/*.fasta>;
        my $size=@files;
        print "I will process $size files \n";
        foreach $files(@files){
        			open ("file", $files);
                                my @file=<file>;
                                my @fasta= grep (!/^>/, @file);
                                grep(s/\s+$//,@fasta);
                                $a=0;
                                foreach $fasta(@fasta){
                                			$a=$a+ length ($fasta);
                                                        }
                                print output "$files\t$a\n";
                                $a=0;
                                }




