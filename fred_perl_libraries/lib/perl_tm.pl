#!/usr/bin/perl -w
#
#   Code borrowed from PerlPrimer, Copyright © 2003-2005, Owen Marshall (owenjm@users.sourceforge.net)
#

use strict;

package PerlTm;

# Load thermodynamic data and genetic code...
my (%oligo_dH, %oligo_dH_full, %oligo_dS, %oligo_dS_full, %genetic_code);
		
# Starting ionic concentration variables
my $oligo_conc = 50;			#in nM
my $monovalent_cation_conc = 50;	#in mM

# These are not used if $mg_conc < $dntp_conc -fjel
my $mg_conc = 0;			#in mM
my $dntp_conc = 0.2;			#in mM


sub exact_tm {
    my ($primer) = @_;

    $primer = uc($primer); # if user enters primer directly as lower-case
    my ($i, $nn, $initterm, $endterm);
    my $primer_len = length($primer);
    my ($deltaH, $deltaS);
	    
    #-----------------------------#
    # calculate deltaH and deltaS #
    #-----------------------------#

    for ($i = 0; $i < $primer_len-1; $i++) {
	$nn = substr($primer, $i, 2);
	$deltaH += $oligo_dH{$nn};
	$deltaS += $oligo_dS{$nn};
    }
	    
    #-------------------------#
    # initial term correction #
    #-------------------------#

    $initterm="init" . substr($primer, 0, 1);
    $deltaH+= $oligo_dH{$initterm};
    $deltaS+= $oligo_dS{$initterm};
    
    $endterm="init" . substr($primer, -1, 1);
    $deltaH+= $oligo_dH{$endterm};
    $deltaS+= $oligo_dS{$endterm};
			    
    # Tm at 1M NaCl
    # $tm= ($deltaH * 1000) / ($deltaS + (1.987 * log($oligo_conc / 4))) - 273.15;
    
    #------------------------------------------#
    # correct for salt concentration on deltaS #
    #------------------------------------------#
    
    # Big problems if [dNTPs] > [Mg++] !!  This is a quick fix ...
    my $salt_correction;
    if ($mg_conc > $dntp_conc) {
	    $salt_correction = sqrt($mg_conc - $dntp_conc);
    } else {
	    $salt_correction = 0;
    }
    
    my $na_eq = ($monovalent_cation_conc + 120 * $salt_correction)/1000;
    
    # deltaS correction:
    $deltaS += (0.368 * ($primer_len - 1) * log($na_eq));
    
    my $oligo_conc_mols = $oligo_conc / 1000000000;

    # Salt corrected Tm
    # NB - for PCR I'm assuming for the moment that the [strand target] << [oligo]
    # and that therefore the C(t) correction term approx equals [oligo]
    my $F = 4;	# was 1, but MELTING uses 4	-fjel
    my $corrected_tm = (($deltaH * 1000) / ($deltaS + (1.987 * log($oligo_conc_mols/$F)))) - 273.15;
    return sprintf "%.2f", $corrected_tm;
}

#
#   Approx. melting temperature for long oligos
#
sub approx_tm {
    my ($primer) = @_;

    $primer = uc($primer); # if user enters primer directly as lower-case
    my $primer_len = length($primer);

    my $GC;
    for my $c (split //, $primer) {
	$GC++ if ($c eq 'G' || $c eq 'C');
    }
    my $percent_gc = ($GC / $primer_len) * 100;

    # Big problems if [dNTPs] > [Mg++] !!  This is a quick fix ...
    my $salt_correction;
    if ($mg_conc > $dntp_conc) {
	    $salt_correction = sqrt($mg_conc - $dntp_conc);
    } else {
	    $salt_correction = 0;
    }
    my $na_eq = ($monovalent_cation_conc + 120 * $salt_correction)/1000;

    return sprintf "%.2f", 81.5 + 16.6 * log10($na_eq / (1.0 + 0.7 * $na_eq))
                + 0.41 * $percent_gc
                - 500.0 / $primer_len;
}


sub load_data {
	#-----
	#
	# NN thermodynamics hashes (AA = 5' AA 3'/3' TT 5') derived from ...
	# 
	# Allawi HT, SantaLucia J Jr.  Thermodynamics and NMR of internal G.T mismatches in DNA.
	# 	Biochemistry. 1997 Aug 26;36(34):10581-94
	#
	# SantaLucia J Jr.  A unified view of polymer, dumbbell, and oligonucleotide DNA nearest-neighbor thermodynamics.
	# 	Proc Natl Acad Sci U S A. 1998 Feb 17;95(4):1460-5. 
	# 
	# ... with mismatch dG data (AGTG = 5' AG 3'/3' TG 5') derived from ...
	# 
	# Peyret N, Seneviratne PA, Allawi HT, SantaLucia J Jr.  Nearest-neighbor thermodynamics and NMR of DNA sequences with internal A.A, C.C, G.G, and T.T mismatches.
	# 	Biochemistry. 1999 Mar 23;38(12):3468-77. 
	# 
	# Allawi HT, SantaLucia J Jr.  Nearest-neighbor thermodynamics of internal A.C mismatches in DNA: sequence dependence and pH effects.
	# 	Biochemistry. 1998 Jun 30;37(26):9435-44.
	# 
	# Allawi HT, SantaLucia J Jr.  Thermodynamics of internal C.T mismatches in DNA.
	# 	Nucleic Acids Res. 1998 Jun 1;26(11):2694-701. 
	# 
	# Allawi HT, SantaLucia J Jr.  Nearest neighbor thermodynamic parameters for internal G.A mismatches in DNA.
	# 	Biochemistry. 1998 Feb 24;37(8):2170-9.
	# 
	# Allawi HT, SantaLucia J Jr.  Thermodynamics and NMR of internal G.T mismatches in DNA.
	# 	Biochemistry. 1997 Aug 26;36(34):10581-94
	# 
	#-----
	
	#-------------------#
	# deltaH (kcal/mol) #
	#-------------------#
	
	%oligo_dH = qw(
		AA -7.9 TT -7.9 
		AT -7.2 TA -7.2 
		CA -8.5 TG -8.5 
		GT -8.4 AC -8.4 
		CT -7.8 AG -7.8 
		GA -8.2 TC -8.2 
		CG -10.6 GC -9.8 
		GG -8.0 CC -8.0 
		initC 0.1 initG 0.1 
		initA 2.3 initT 2.3
	);
	
	%oligo_dH_full=(
		qw(AATT -7.9 	TTAA -7.9 
		ATTA -7.2 	TAAT -7.2 
		CAGT -8.5 	TGAC -8.5 
		GTCA -8.4 	ACTG -8.4 
		CTGA -7.8 	AGTC -7.8 
		GACT -8.2 	TCAG -8.2 
		CGGC -10.6 	GCCG -9.8 
		GGCC -8.0 	CCGG -8.0
			
		initC 0.1 	initG 0.1 
		initA 2.3 	initT 2.3),
		
		# Like pair mismatches 
			
		qw(AATA 1.2 	ATAA 1.2
		CAGA -0.9 	AGAC -0.9
		GACA -2.9 	ACAG -2.9
		TAAA 4.7 	AAAT 4.7 
		
		ACTC 0.0 	CTCA 0.0 
		CCGC -1.5 	CGCC -1.5
		GCCC 3.6 	CCCG 3.6 
		TCAC 6.1 	CACT 6.1 
		
		AGTG -3.1 	GTGA -3.1
		CGGG -4.9 	GGGC -4.9
		GGCG -6.0 	GCGG -6.0
		TGAG 1.6 	GAGT 1.6 
		
		ATTT -2.7 	TTTA -2.7
		CTGT -5.0 	TGTC -5.0
		GTCT -2.2 	TCTG -2.2
		TTAT 0.2 	TATT 0.2  ),
		
		# G.T mismatches 
		
		qw(AGTT 1.0  	TTGA 1.0
		ATTG  -2.5 	GTTA  -2.5
		CGGT  -4.1 	TGGC  -4.1
		CTGG  -2.8 	GGTC  -2.8
		GGCT  3.3 	TCGG  3.3
		GGTT  5.8 	TTGG  5.8
		GTCG  -4.4 	GCTG  -4.4
		GTTG  4.1 	GTTG  4.1
		TGAT  -0.1 	TAGT  -0.1
		TGGT  -1.4 	TGGT  -1.4
		TTAG  -1.3 	GATT  -1.3), 
		
		# G.A mismatches 
		
		qw(AATG  -0.6 	GTAA  -0.6
		AGTA  -0.7 	ATGA  -0.7
		CAGG  -0.7 	GGAC  -0.7
		CGGA  -4.0 	AGGC  -4.0
		GACG  -0.6 	GCAG  -0.6
		GGCA  0.5 	ACGG  0.5
		TAAG  0.7 	GAAT  0.7
		TGAA  3.0 	AAGT  3.0), 
		
		# C.T mismatches 
		
		qw(ACTT  0.7 	TTCA  0.7
		ATTC  -1.2 	CTTA  -1.2
		CCGT  -0.8 	TGCC  -0.8
		CTGC  -1.5 	CGTC  -1.5
		GCCT  2.3 	TCCG  2.3 
		GTCC  5.2 	CCTG  5.2 
		TCAT  1.2 	TACT  1.2 
		TTAC  1.0 	CATT  1.0), 
		
		# A.C mismatches 
		
		qw(AATC  2.3	CTAA  2.3
		ACTA  5.3 	ATCA  5.3 
		CAGC  1.9 	CGAC  1.9 
		CCGA  0.6 	AGCC  0.6 
		GACC  5.2 	CCAG  5.2 
		GCCA  -0.7 	ACCG  -0.7
		TAAC  3.4  	CAAT  3.4 
		TCAA  7.6 	AACT  7.6),
	
	);
	
	#--------------------#
	# deltaS (cal/K.mol) #
	#--------------------#
	
	%oligo_dS=qw(
		AA -22.2 TT -22.2 
		AT -20.4 TA -21.3 
		CA -22.7 TG -22.7 
		GT -22.4 AC -22.4 
		CT -21.0 AG -21.0 
		GA -22.2 TC -22.2 
		CG -27.2 GC -24.4 
		GG -19.9 CC -19.9 
		initC -2.8 initG -2.8 
		initA 4.1 initT 4.1 
		sym -1.4
	);
	
	%oligo_dS_full=(
		qw(AATT -22.2 	TTAA -22.2 
		ATTA -20.4 	TAAT -21.3 
		CAGT -22.7 	TGAC -22.7 
		GTCA -22.4 	ACTG -22.4 
		CTGA -21.0 	AGTC -21.0 
		GACT -22.2 	TCAG -22.2 
		CGGC -27.2 	GCCG -24.4 
		GGCC -19.9 	CCGG -19.9
			
		initC -2.8 	initG -2.8 
		initA 4.1 	initT 4.1
		sym -1.4),
		
		# Like pair mismatches
			
		qw(AATA 1.7 	ATAA 1.7
		CAGA -4.2 	AGAC -4.2 
		GACA -9.8 	ACAG -9.8 
		TAAA 12.9 	AAAT 12.9 
		
		ACTC -4.4 	CTCA -4.4 
		CCGC -7.2 	CGCC -7.2 
		GCCC 8.9 	CCCG 8.9 
		TCAC 16.4 	CACT 16.4 
		
		AGTG -9.5 	GTGA -9.5 
		CGGG -15.3 	GGGC -15.3
		GGCG -15.8 	GCGG -15.8
		TGAG 3.6 	GAGT 3.6 
		
		ATTT -10.8 	TTTA -10.8
		CTGT -15.8 	TGTC -15.8
		GTCT -8.4 	TCTG -8.4 
		TTAT -1.5 	TATT -1.5),
		
		# G.T mismatches
		
		qw(AGTT 0.9 	TTGA 0.9
		ATTG  -8.3 	GTTA  -8.3
		CGGT  -11.7 	TGGC  -11.7
		CTGG  -8.0 	GGTC  -8.0
		GGCT  10.4 	TCGG  10.4
		GGTT  16.3 	TTGG  16.3
		GTCG  -12.3 	GCTG  -12.3
		GTTG  9.5 	GTTG  9.5
		TGAT  -1.7 	TAGT  -1.7
		TGGT  -6.2 	TGGT  -6.2
		TTAG  -5.3 	GATT  -5.3), 
		
		# G.A mismatches
		
		qw(AATG  -2.3 	GTAA  -2.3
		AGTA  -2.3 	ATGA  -2.3
		CAGG  -2.3 	GGAC  -2.3
		CGGA  -13.2 	AGGC  -13.2
		GACG  -1.0 	GCAG  -1.0
		GGCA  3.2 	ACGG  3.2
		TAAG  0.7 	GAAT  0.7
		TGAA  7.4 	AAGT  7.4), 
		
		# C.T mismatches
		
		qw(ACTT  0.2 	TTCA  0.2
		ATTC  -6.2 	CTTA  -6.2
		CCGT  -4.5 	TGCC  -4.5
		CTGC  -6.1 	CGTC  -6.1
		GCCT  5.4 	TCCG  5.4 
		GTCC  13.5 	CCTG  13.5
		TCAT  0.7 	TACT  0.7 
		TTAC  0.7 	CATT  0.7), 
		
		# A.C mismatches
		
		qw(AATC  4.6 	CTAA  4.6
		ACTA  14.6 	ATCA  14.6
		CAGC  3.7 	CGAC  3.7 
		CCGA  -0.6 	AGCC  -0.6
		GACC  14.2 	CCAG  14.2
		GCCA  -3.8 	ACCG  -3.8
		TAAC  8.0  	CAAT  8.0 
		TCAA  20.2 	AACT  20.2),
	
	);
	
	
	# Genetic code hash
	%genetic_code=qw(
			TTT F TTC F TTA L TTG L
			CTT L CTC L CTA L CTG L
			ATT I ATC I ATA I ATG M
			GTT V GTC V GTA V GTG V
			TCT S TCC S TCA S TCG S
			CCT P CCC P CCA P CCG P
			ACT T ACC T ACA T ACG T
			GCT A GCC A GCA A GCG A
			TAT Y TAC Y TAA * TAG *
			CAT H CAC H CAA Q CAG Q
			AAT N AAC N AAA K AAG K
			GAT D GAC D GAA E GAG E
			TGT C TGC C TGA * TGG W
			CGT R CGC R CGA R CGG R
			AGT S AGC S AGA R AGG R
			GGT G GGC G GGA G GGG G
	);
}

sub log10 {
    return log($_[0]) / log(10);
}


&load_data;

1;
