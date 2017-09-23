#! /usr/bin/perl -w
#******************************************************************************
#
#                L519 - Lab Session #1  gb2fasta2.pl
#                       GenBank to FASTA format conversion
#
#                                                Written By Junguk HUR
#
#  Desc   :   * gb2fasta2.pl accepts user's command line option
#               via Getopt module
#
#******************************************************************************

# To use this perl script in a strict manner with all possible warnings
use strict;

# Declaration of package to be used for commandline options
use Getopt::Long;

# Variable Init. for arguments and options
my $gbkFile = '';           # Input 'gbk' file name
my $fastaFile = '';         # Output 'FASTA' file name

# Getting user's argument from command line
GetOptions ( "gbk=s"       => \$gbkFile,
             "fasta=s"     => \$fastaFile );

# Option & File Check
if (($gbkFile eq "") || ($fastaFile eq ""))
{   die "\n*** Sample Usages ***\n\>perl gb2fasta2.pl -gbk <gbkFile>".
        " -fasta <fastaFile>\n";
}else
{   open (GBK, $gbkFile) || die "Cannot open genbank file $gbkFile\n";
}

# Read the gbk file into array 'gbkLine'
my @gbkLine = <GBK>;

# Initialize varialbles
my $in_sequence = 0;
my $locus = '';
my $DNA = '';

# Read every Genbank line
foreach my $line ( @gbkLine )
{   if ($line =~ /^\/\/\n/ )
    {   last;    # exit foreach loop when encountered //\n
    }elsif ($in_sequence)
    {   $DNA .= $line;   # add current line to $DNA
    }elsif ($line =~ /^ORIGIN/)
    {   $in_sequence = 1;
    }elsif ($line =~ /^LOCUS\s+(\S+)/)
    {   $locus = $1;
    }
}

# Remove whitespace, new line, and numbers from the sequence
$DNA =~ s/\s|\n|\d//g;

# Open FASTA output file
open (FASTA, ">./$fastaFile");

# Print Comment Line (Header Line)
print FASTA ">$locus\n";

# Print sequence line by calling print_sequence subroutine
print_sequence_into_file(\*FASTA, $DNA, 70);  # 60 characters per line

close FASTA;
close GBK;
exit;




# subroutine print_sequence_into_file
# print $sequence into $FILE with $length character per line
sub print_sequence_into_file
{   my($FILE, $sequence, $length) = @_;

    use strict;
    use warnings;

    # Print sequence in lines of $length
    for ( my $pos = 0 ; $pos < length($sequence) ; $pos += $length )
    {   print $$FILE substr($sequence, $pos, $length), "\n";
    }
}


