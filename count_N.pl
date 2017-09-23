#!/usr/bin/perl
print "count_N.pl <List of file names> < output file> <which character to count>\n";
open ("input", $ARGV[0]) || die "paka mat\n";
open ("output",">$ARGV[1]") || die "bola na paka maat";
if ($ARGV[2]){} else {die "What character should I count ?\n";}

while (<input>){
				chomp;
				$b=$_;
				open ("fasta" , "$b") || die " Error opening $_. Make sure the name is correct and the file exists\n";
				system ("fasta2tabbed 1 2 $b| sed 1d > $b.tab");
				open ("tabbed", "$b.tab") || die " You proposed I disposed. Something went wrong at line 10 \n";
				print "Counting $ARGV[2] in $b \n";

				@tabbed1=<tabbed>; # 1 element in the array @tabbed1;
                grep(s/\s+$//,@tabbed1);
                @tabbed=split (/\t/, $tabbed1[0]); # 2 elements in the array @tabbed
                #@bases= split (//, $tabbed[1]); # array @bases have all the bases
                my $n=0;
                for (split //, $tabbed[1]){
                		      $n++ if $_ eq "$ARGV[2]";
                                      }
                 print output "$b\t$n\n";
                 unlink "$b.tab";
                 }


