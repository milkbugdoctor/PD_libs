#!/usr/bin/perl
use warnings;
use Cwd;

print "usage format_fasta.pl <output.fatsa>\n";
my $dir=getcwd;



@files=<$dir/*.fasta>;
$size=@files;

print " The current working Dir is $dir and I will process $size Fasta Files\n";
open (result,">$ARGV[0]")|| die "No output file specified \n";
$n=1;
#foreach $files(@files){system "dos2unix $files"};
foreach $files(@files){
                        
                        open (input, $files);
                        my @input=<input>;
                        @name=split(/\//,$files);
                        grep (s/.final.scaffolds.fasta//,@name);
                        $a=@name;
                        print "$name[$a-1]\n";
                        #@taxon=split(/\./,$name[$a-1]);
                        #print "$taxon[0]\n";
                        #grep (s/>/>Archea_$n|kraken:taxid|$taxon[0]|/,@input);
                        
                        #grep (s/^\s+//,@input);
                        grep (s/>/>$name[$a-1]|/,@input);
                        print (result "@input");
                        $n=$n+1;
                        
                       }
#system ("dos2unix $ARGV[0]");






