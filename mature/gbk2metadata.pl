#!/usr/bin/perl
#use warnings;
use BeginPerlBioinfo;
use Data::Dumper;
use File::Slurp;


print "Usage: gbk2metadata.pl <list of NCBI gbk file> \nThis script extracts all attributes from the SOURCE field of the Genbank file\n";

open ("sample", "$ARGV[0]") || die "List of files not specified\n";
@sample=<sample>;
grep(s/\s+$//, @sample);





$i=0;
foreach $sample(@sample){

													# Declare and initialize variables	
													my $library = "$sample" ;
													my $fh;
													my $record;
													my $dna;
													my $annotation;
													my %fields;
													my @features;
													
													$fh = read_file ("$sample");


																						$record=$fh;
																						#print "$record";
																						@record=split(/\n/, $record);
																						
																						my @recordid=grep s/ACCESSION   //, @record; # get accession number
																						#foreach (@record){print "$_\n";}
																						($annotation, $dna) = get_annotation_and_dna($record);
																						%fields = parse_annotation($annotation);

																						# Extract the features from the FEATURES table
																						@features = parse_features($fields{'FEATURES'});
																						#$a=@features;
																						
																						my @org=grep /ORGANISM/, @features;
																						chomp (@org);
																						foreach (@org){print "$_\n";}
																						
																						
																						my @source=grep /source/, @features;
																						#my @source=grep /SOURCE/, @features
																						chomp (@source);
																					  #foreach (@source){print "$_\n";}
																						
																						
																						grep(s/\s+$//s, @source);
																						grep(s/^ {21}//s, @source);
																						grep(s/^ {5}//s, @source);
																						#grep(s/\///, @source_p);
																						
																						grep(s/ {10}//, @source);
																						grep(s/source/\/source=/, @source);
																						
																						my @source_p=split(/\//, $source[0]);
																						grep(s/=/\t/, @source_p);
																						grep(s/\s+$//s, @source_p);
																						grep(s/ {21}//s, @source_p);
																						grep(s/\n//s, @source_p);
																						
																						#my$b=@source_p;
																						#print "there are $b fields in $recordid[0] \n";
																						open("output",">$recordid[0].metainfo") || die "Need Permission to write here";
																						foreach (@source_p){print output "$_\n";}
																						close "output";
																						undef (@source_p);
																						undef (@source);
																						$i++;															
}
print "parsed $i Records\n";

exit;
