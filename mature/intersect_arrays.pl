#!/usr/bin/perl
use Array::Utils qw(:all);
print "usage: intersect_array.pl <file_1> <file_2> \n";
open (file1, $ARGV[0]) || die "File 1 not found\n";
open (file2, $ARGV[1]) || die "File 2 not found\n";
open (intersect1, ">$ARGV[0]_$ARGV[1]_intersect.tab") || die "Cant create intersect file file\n";
open (file1_s, ">$ARGV[0]_specific.tab") || die "cant write output file\n";
open (file2_s, ">$ARGV[1]_specific.tab") || die "fuck off\n";

@file1=<file1>;
grep(s/\s+$//,@file1);

@file2=<file2>;
grep(s/\s+$//,@file2);

@intersect1=intersect(@file1, @file2);
foreach (@intersect1){ print intersect1  "$_\n";}

@file1_specific=array_minus(@file1, @file2);
foreach (@file1_specific){ print file1_s "$_\n";}

@file2_specific=array_minus(@file2, @file1);
foreach (@file2_specific){ print file2_s "$_\n";}

