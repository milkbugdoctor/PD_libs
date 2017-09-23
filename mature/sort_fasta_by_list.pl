#!/usr/bin/perl -w
use Bio::Index::Fasta;

print "USAGE: sort_fasta_by_list.pl <fasta_file> <list file> \nSample_names = Tab delimited file 1 fasta name per line\n";

open (sample, "$ARGV[0]")|| die "Fasta file not specified\n";
if ($ARGV[1]){}else { die "List file not specified\n";}
if ($ARGV[2]){}else { die "Output file not specified\n";}
#
# make index
#
my $Index_File_Name = "tmp.idx";
my $idx             = Bio::Index::Fasta->new(
 '-filename'   => $Index_File_Name,
 '-write_flag' => 1
);
$idx->make_index($ARGV[0]);

#
# open the list
#
open( my $list, $ARGV[1] ) or die "Could not open $List_File_Name !";

#open( output, ">$ARGV[2]" ) or die "Could not open output file";
#
# write to filehandle using list and index
#
my $out = Bio::SeqIO->new( '-format' => 'Fasta', '-fh' => \*STDOUT );
while ( my $id = <$list> ) {
 chomp $id;
 my $seq = $idx->fetch($id); 
 $out->write_seq($seq);
}