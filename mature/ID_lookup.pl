#!/usr/bin/perl
use Array::Utils qw(:all);
print "Usage: ID_lookup.pl <Database_file> <ID_file> <Result_file> <Field_number_to_search_against_in_database> <Field_number_in_ID_file>\n";

open ("database",$ARGV[0])||die "No database file specified\n";

open ("query", $ARGV[1])|| die "No query file specified\n";
@query=<query>;
$e=@query;
grep(s/\s+$//, @query);

open ("output", ">$ARGV[2]")|| die " No output file specified\n";


if ($ARGV[3]){} else { die "Need to specify the field number to search against\n";}
$field= $ARGV[3]-1;
#print "value of field is $field\n";

if ($ARGV[4]){} else { die "Need to specify the field number of the ID file\n";}
$ifield=$ARGV[4]-1;

my %database;

while (<database>){
                   chomp $_;
                   @data=split(/\t/, $_);
                   $database{"$data[$field]"}=$_;
                   #print "$data[$field] =$_ \n";
                   push (@allids, "$data[$field]");
                   }
print "Read in the database\nNow creating the output file\n";


foreach $query(@query){
                       @query1=split(/\t/,$query);
                       push (@query2, "$query1[$ifield]");
                       if ($database{$query1[$ifield]}){
                       print output "$query\t$database{$query1[$ifield]}\n";
                       }
                       undef @query1;
                       }

print "Checking if I missed anything\n";

@query_specific=array_minus(@query2, @allids);
$a=@query_specific;

print "$a IDs not found \n";

if ($a){
	print " writing missing IDs to file $ARGV[2].missing.tab\n";
        open ("missing", ">$ARGV[2].missing.tab");
        foreach (@query_specific){ print missing "$_\n";}
        }

