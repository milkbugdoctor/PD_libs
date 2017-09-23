#!/usr/bin/perl
#use warnings;
use Cwd;
use Scalar::Util qw(looks_like_number)
print "Usage: count_sam.pl <annotation_features>\n";

my $dir1=getcwd;
my @files3=<$dir1/*.dedup.bam>;
my $size=@files3;
print " The current working Dir is $dir and I will process $size deduplicated bam files\n";

foreach $files3(@files3){ system (" samtools view -h -f 0x0040 $files3 | sed  '/\t0\t0\t/d'> $files3.read1.sam");}



open ("anno", $ARGV[0])|| die "Cant open Annotation file\n";
@annotation=<anno>;
grep(s/\s+$//,@annotation);

foreach $annotation(@annotation){# Make a hash with positions as keys and locus tags as the value
				my @cols=split (/\t/, $annotation);
                                push (@cols1, $cols[1]);
                                $c=@cols1;
                                #print "$cols[1]\n";
                                %plasmid;
                                if ($cols[0] eq 'CP001362'){
                                			for ($i=$cols[2]; $i<=$cols[3]; $i++){
                                                        					if ($cols[4] eq '-'){ $plasmid{"-$i"}=$cols[1];}
                                                                                                if ($cols[4] eq '+') { $plasmid{$i}=$cols[1];}
                                                                                              }
                                                       }
                               %chr;
                                if ($cols[0] eq 'CP001363'){
                                                        for ($i=$cols[2]; $i<=$cols[3]; $i++){
                                                        					if ($cols[4] eq '-'){ $chr{"-$i"}=$cols[1];}
                                                                                                if ($cols[4] eq '+') { $chr{$i}=$cols[1];}
                                                                                              }
                                                       }

                                   }
#foreach $anno(keys %plasmid){ print "$anno\t $plasmid{$anno}\n";}
#foreach $anno1(keys %chr){ print "$anno1\t %chr{$anno1}\n";}
my $dir=getcwd;
my @files=<$dir/*.dedup.bam.read1.sam>;
my $size=@files;
print " The current working Dir is $dir and I will process $size deduplicated bam files\n";

foreach $files(@files){
                        @file1=split(/\//, $files);
                        $x=@file1;
                        print "Processing $file1[$x-1]\n";
                        open ("output", ">$files.count")|| die "Need permission to write on the disk\n";
                        open ("input", "$files") || die "Something is wrong, I cant open $files\n";
                        my @input=<input>;
                        $b=@input;
                        foreach $input(@input){

                        			@input1=split (/\t/, $input);
                                                if ($input1[2] eq 'CP001362' && $input1[8] gt 0){ push (@output1, $plasmid{$input1[3]});}
                                                if ($input1[2] eq 'CP001362' && $input1[8] lt 0) {
                                                						  $p=$input1[3]; # 3 prime end of the read1 on negative strand
                                                                                                  $q=$input1[5]; # CIGAR string
                                                                                                  $A= split (/\d+[IDNSHP]/, $q);
                                                                                                  $B=0;
												  foreach (@A){
														s/\D//;
                												$B=$B+$_;
                												}
                                                                                                  $5end=$p+$B;
                                                                                                  push (@output1, $plasmid{-$5end});
                                                                                                  }







                                                if ($input1[2] eq 'CP001363' && $input1[8] gt 0){ push (@output1, $chr{$input1[3]});}
                                                if ($input1[2] eq 'CP001363' && $input1[8] lt 0){
                                                                                                  $p=$input1[3]; # 3 prime end of the read1 on negative strand
                                                                                                  $q=$input1[5]; # CIGAR string
                                                                                                  $A= split (/\d+[IDNSHP]/, $q);
                                                                                                  $B=0;
												  foreach (@A){
														s/\D//;
                												$B=$B+$_;
                												}
                                                                                                  $5end=$p+$B;
                                                                                                  push (@output1, $plasmid{-$5end});
                                                                                                  }




                                                $a=@output1;
                                                }
                                                print "Reads mapped to genome = $a\n";
                                                my %count;
                                                foreach (@output1) {
                                                                  if (exists $count{$_}) {
                                                                                          $count{$_}++;
                                                                                          }
                                                                                          else {
                                                                                               $count{$_} = 1;
                                                                                               }
                                                                                          }

                                                                                          foreach (keys %count) {
                                                                                                               #print output "$_ \t $count{$_}\n";
                                                                                                               push (@output,"$_\t$count{$_}\n");
                                                                                                               push (@present, "$_");
                                                                                                                }

                                                                                          %seen=();
                                                                                          @absent= ();

                                                                                          foreach $item(@present) { $seen {$item} =1; }

                                                                                          foreach $item(@cols1){
                                                                                          			unless ($seen{$item}){
                                                                                                                			push (@absent, $item);
                                                                                                                                        }
                                                                                                                }


                                                                                          foreach $absent(@absent){ push (@output, "$absent\t0\n");}
                                                                                          @sorted=sort (@output);
                                                                                          print output "Gene\t$file1[$x-1]\n";
                                                                                          foreach $output(@sorted){ print output "$output";}
                                                                    undef @output1;
                                                                    undef @output;
                                                                    undef @present;
                          }

print "There are $c total attempted mutant sites\n";

system ("sed -i 's/^\t/unmapped\t/' *.dedup.bam.read1.sam.count");
