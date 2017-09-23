#!/usr/bin/perl -w
# Pre-process transposon sequence data from fastq file
# identifies the exact matching MID/primer tags  and removes them 
# from the sequence. In addition, it removes any poly A sequence (and any
# sequence that follows), if needed. Additionally, convert Illumina quality
# scores to sanger quality scores.
# This is non-bioperl version and is >25x faster than bioperl
# IMPORTANT: This script assumes that the sequence and qual score are in one line
# Author: Shrinivasrao P. Mane, PhD
# Author: Andrew Warren
# Date Last Modified: 08/31/12
# Version: 0.6
use 5.010;
use strict;
use warnings;
use String::Approx 'amatch';
use JSON;
#use Bio::SeqIO;
use Getopt::Std;
getopts "i:p:q:s:ch";
our ($opt_p,$opt_i,$opt_h,$opt_c,$opt_q,$opt_s);

HelpMsg() if defined $opt_h;
die Usage() if (!defined $opt_i or !defined $opt_p);

my $file = $opt_i;#"dumSeq.fq";
#my $key  = $opt_t; #"ATTAAGATGTGTATAAG";
my $param_file  = $opt_p;

my $jparam;
{
    open(FILE, $param_file) or die "Could not open '$file'\n";
    local $/ = undef;
    $jparam = <FILE>;
}
my $json = JSON->new->allow_nonref;
my $param = $json->decode($jparam);
#print $param,"\n";

my %seen_read_ids;
my %all_mids;
my %midCnter;
my %fhs;
my $mid_length=0;
# reorganize the keys to make this script much faster;
foreach my $allkeys (@{$param}){
	foreach my $key (sort keys %{$allkeys}){
		$mid_length=length($allkeys->{$key}->{mid});
		if(!defined $opt_s){
			open($fhs{$key},">$key\.fq") or die "Couldn't open file: $key\.fq; $!\n";
		}
		if (defined $opt_s){
			open($fhs{$key},">$key.P01\.fq") or die "Couldn't open file: $key\.fq; $!\n";
			open($fhs{$key."2"},">$key.P02\.fq") or die "Couldn't open file: $key\.fq; $!\n";
		}
		push @{$all_mids{$allkeys->{$key}->{mid}}},({
			label          => $key,
			primer         => $allkeys->{$key}->{primer},
			mismatch       => $allkeys->{$key}->{mismatch},
			suffix         => $allkeys->{$key}->{suffix},
			polyAlen       => $allkeys->{$key}->{polyAlen},
			polyAprefixLen => $allkeys->{$key}->{polyAprefixLen}
			});
	}
}
my $minSeqLength=4; # the program will print seq >4 bp

#my $remNumBases=0; #number of (random) bases to remove after the key
#$remNumBases=$opt_s if defined $opt_s;
#my $bases="."x$remNumBases;
##my $word="$key$bases";
#my $polyAlen=$opt_a if defined $opt_a; #8;
#$key="$key$opt_c" 

# Solexa->Sanger quality conversion table
my @conv_table;
for (-64..64) {
	$conv_table[$_+64] = chr(int(33 + 10*log(1+10**($_/10.0))/log(10)+.499));
}


open(FILE,$file) or die $!;
my ($id,$seq,$id2,$qual);
my $cnt=0;
my $f=0;#this is some sort of toggle that goes to 1 after second ID for the quality string and goes to 0 after the quality string is processed
my $read_key="";
while(<FILE>){
	chomp;
	#next unless /\S+/;
	if(/^\@(\S+)/){
		$id=$1;
		$read_key=$id;
		$read_key=~s/\/1$//;
		$read_key=~s/^\@//;
		#print "$read_key\n";
	}elsif(/^\+(\S+)/){
		$id2=$1;
		$f=1;
	}elsif(/^([ATGCN]+)/ and $f==0){
		$seq=$1;
	}else{
		$qual=$_;
		$f=0;
		$cnt++;
		#print "\@$id\n$seq\n\+$id2\n$qual\n";
		#print "$mid\t$seq\n";
		my $seqMid=substr($seq,0,$mid_length);#grab the Mutant ID from the front of the stringi
		if(exists $all_mids{$seqMid}){#check that the mutant ID from the sequence is exactly as one from the JSON file
			#$midCnter{$all_mids{$seqMid}->{label}}++;
			#print $all_mids{$seqMid}->{label},"\n";
			my $numSamples=scalar @{$all_mids{$seqMid}};
			for (my $i=0;$i<$numSamples;$i++){
				my $numMism=${$all_mids{$seqMid}}[$i]->{mismatch};#get number of allowed mismatches in primer
				my $primer=${$all_mids{$seqMid}}[$i]->{primer};
				my $sample=${$all_mids{$seqMid}}[$i]->{label};
				my $primerLength=length($primer);
				$seq=~s/^$seqMid//;
				my $primTestString =substr($seq,0,$primerLength);
				if(approxMatch($primTestString,$primer,$numMism)){#check that the primer string is present allowing for specified number of mismatches
					#print ($primTestString eq $primer);
					#print " MATCH: $primer\t$primTestString\n";
					$seq=~s/^$primTestString//;
					my $suffix=${$all_mids{$seqMid}}[$i]->{suffix};
					if($seq=~/^$suffix/){#strip down the sequence and quality strings to account for primer+suffix+SEQUENCE+polyA's
						$seq=~s/^$suffix//;
						my $word="$seqMid$primer$suffix";
						my $polyAlen=${$all_mids{$seqMid}}[$i]->{polyAlen};
						my $polyAprefixLen=${$all_mids{$seqMid}}[$i]->{polyAprefixLen};
						$seq=~s/.{0,$polyAprefixLen}A{$polyAlen,}.*$//i;
						$qual= substr($qual,length($word),length($seq));
						$qual=substr($qual,0,length($seq));
						$qual=sol2std($qual) if defined $opt_q;
						if (length($seq)>=$minSeqLength){
							print {$fhs{$sample}} "\@$id\n$seq\n\+$id2\n$qual\n";
							$seen_read_ids{$read_key}=$sample;
							$midCnter{$sample}++;
						}
					}
				}
			}
		}
	}
}

close(FILE);

if(defined $opt_s){
	open(FILE2,$opt_s) or die $!;
	my ($id,$seq,$id2,$qual);
	my $f=0;#this is some sort of toggle that goes to 1 after second ID for the quality string and goes to 0 after the quality string is processed
	my $read_key ="";
	while(<FILE2>){
		chomp;
		#next unless /\S+/;
		if(/^\@(\S+)/){
			$id=$1;
			$read_key=$id;
			$read_key=~s/\/1$//;
			$read_key=~s/^\@//;
			#print "$read_key\n";
		}elsif(/^\+(\S+)/){
			$id2=$1;
			$f=1;
		}elsif(/^([ATGCN]+)/ and $f==0){
			$seq=$1;
		}else{
			$qual=$_;
			$f=0;
			if (exists $seen_read_ids{$read_key}){
				print {$fhs{$seen_read_ids{$read_key}."2"}} "\@$id\n$seq\n\+$id2\n$qual\n";
			}
		}
	}
}
print STDERR "Processed $cnt sequences\n";
my $j=0;
foreach my $label (sort keys %midCnter){
	print STDERR "$midCnter{$label} sequences from : $label\n";
	$j+=$midCnter{$label};
}
print STDERR "Rescued $j sequences\n";

exit;


sub approxMatch {
 
  $_ = shift;
  my $primer=shift;
  my $numMism=shift;
  return amatch($primer, [  # this array sets match options:
                            "i",    # match case-insensitively
                            #"0%",  # tolerate 0 character in 10 being wrong
                            "S$numMism",   # but no substituting one character for another
                            "D0",   # tolerate up to one deletion
                            "I0"    # and tolerate up to 0 insertions
                           ]);
 
}


sub pred2fq_qual{
	my $qual=shift;
	my @qual=split(" ",$qual);
	my $fq_qual="";
	foreach my $Q (@qual){
		my $q = chr(($Q<=93? $Q : 93) + 33); # converts phred qual score to ascii qual score
		# http://maq.sourceforge.net/fastq.shtml
		$fq_qual .=  $q;
	}
	return $fq_qual;
}

sub getQual{
	my ($qual_score,$start,$length)=@_;
	my @quality=split(" ",$qual_score);
	my $len=scalar(@quality);
	my @splice_score=splice(@quality,$start-1,$length);
	return join(" ",@splice_score);
}

sub sol2std { # http://maq.sourceforge.net/fq_all2std.pl
	my $quals=shift;
	my @t = split('', $quals);
	my $qual = '';
	$qual .= $conv_table[ord($_)] for (@t);
	return $qual;
}


sub HelpMsg{
        print STDERR Usage();
        print STDERR <<EOM;
		-i      fastq
		-p      JSON formatted MID, primer sequence file 
		-q      convert illumina qual. scores to sanger format
		-h      print this message
		-s	second file for paired end mode
EOM
        exit(0);
        
}
#die "Usage : \'perl $0 -l <contig_list_file> -i <fasta_file> -p prefix -f 300 \' \n" if (!defined $opt_l or !defined $opt_i);

sub Usage{
        return "Usage: $0 (-h) (-q) (-a num) (-s num) [-i fastq] [-t tag seq]  >outfile.fq\nUse $0 -h for more help\n";
}
