#!/usr/bin/perl
#use warnings;
use Cwd;
#$dir =getcwd;
open (refe,$ARGV[0])|| die "No refernce mapping file specified\nColumn 1=File Name\nColumn 2=Ref Fasta\n";
@files=<refe>;
grep(s/\s+$//, @files);

my $size=@files;
print "I will process $size fasta files \n";
foreach $files(@files){
                        @names=split (/\t/,$files);
                        print "Splitting Contigs for $names[0] with $names[1] as the refernce \n ";
												system ("amos.split_circular_contigs $names[1] $names[0] > $names[0].split");
                        print "Reordering Contings for $names[0] $names[1] as the refernce \n";
                        system ("amos.reorient_contigs -o -n  $names[1] $names[0].split > $names[0].reordered");
                        unlink "$names[0].split";
                        }
