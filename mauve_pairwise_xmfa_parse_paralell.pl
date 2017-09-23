#!/usr/bin/perl
use warnings;
use Cwd;
print "USAGE: perl mauve_pairwise.pl <Reference_genome> <Genome_fasta>\n \n";

if ($ARGV[0]){}else { die "Ref Genome not specified not specified\n";}
if ($ARGV[1]){}else { die "fasta file to be aligned not specified\n";}


                        system ("/sc/kzd/home/desaip18/soft/mauve_snapshot_2015-02-13/linux-x64/progressiveMauve --output=$ARGV[1].xmfa $ARGV[0] $ARGV[1]");
                        system ("parse_xmfa $ARGV[1].xmfa $ARGV[0] $ARGV[1].xmfa");
                        #system ("rm *.sslist");
                        
                       
                       

