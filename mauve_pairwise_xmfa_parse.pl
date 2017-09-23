#!/usr/bin/perl
use warnings;
use Cwd;
print "USAGE: perl mauve_pairwise.pl <Reference_genome> <Genome_list>\n The genome list should be a tab delimited text file\n";

print "The reference genome is $ARGV[0]\n" || die " No reference genome specified\n";

open (input, $ARGV[1])|| die "No genomes list specified\n";
@input=<input>;
grep(s/\s+$//, @input);
$a=@input;
print "I will be processing $a pair-wise aligments using Mauve\n";
$i=1;
foreach $input(@input){
                        print "Processing $i out of $a alignment\n";
                        system ("progressiveMauve --output=$input.xmfa $ARGV[0] $input");
                        system ("parse_xmfa $input.xmfa $ARGV[0] $input.xmfa");
                        $i=i+1;
                        }

# my $dir=getcwd;



# my @files=<$dir/*.xmfa>;
# my $size=@files;
# print " The current working Dir is $dir and I will process $size Fasta Files\n";
# foreach $files(@files){
# 			system ("parse_xmfa $files $ARGV[0] $files")
#                         }
