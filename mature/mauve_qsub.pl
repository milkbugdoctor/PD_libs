#!/usr/bin/perl
#use warnings;
print "USAGE: mauve_qsub.pl <ref_genome> <sample_names>   Sample_names = Tab delimited file Column 1=genome file \n";

if ($ARGV[0]){}else { die "Ref Genome not specified not specified\n";}
open (sample, "$ARGV[1]")|| die "File with sample names is not specified";


@sample=<sample>;
grep(s/\s+$//, @sample);


foreach $sample(@sample){
			 										@names=split(/\t/, $sample);
			 										print "Subbmiting $names[0]\n";
			 										#print  "qsub  -cwd -V -e $names[0].err -b y ~/UCI_scripts/mauve_pairwise_xmfa_parse_paralell.pl $ARGV[0] $names[0] \n";
			 										system ("qsub -cwd -V -e $names[0].err -b y ~/UCI_scripts/mauve_pairwise_xmfa_parse_paralell.pl $ARGV[0] $names[0] ");
			 										#system ("~/UCI_scripts/mauve_pairwise_xmfa_parse_paralell.pl $ARGV[0] $names[0]");
                        }                

