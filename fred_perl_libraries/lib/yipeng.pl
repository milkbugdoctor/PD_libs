
sub get_yipeng_repeats {
    my $tmp = "
AAAAAAAAAA
GGGGCGGGGC
GGGGGCGGGG
GGGGTGGGGG
GGGGGAGGGG
GGGGAGGGGG
CGCCGCCGCC
GGGGGTGGGG
GCGGCGGCGG
CGGCGGCGGC
GGGGCGGGGG
GGGCGGGGCC
CCCCAGCCCC
GCCCCCTCCC
GGGAGGGAGG
GGGGAGGGGA
CTCCTCCTCC
CTCCCCTCCC
CCCCGCCCCG
AGGGGCGGGG
CCCCCAGCCC
GAGGAGGAGG
GGAGGGAGGG
CCTCCTCCCC
TGGGGGTGGG
CCCTCCTCCC
GGGGAGGGGC
GGGTGGGGGG
CCCGCCCCGC
CCTCCCCTCC
GGGCGGGGCG
TGGGGTGGGG
CCCCTCCTCC
CCCTCCCCCA
GGAGGGGGCG
GGGGCGGGGA
AGGGGGCGGG
GGAGGCGGGG
TGGGGAGGGG
CCCCGGCCCC
CTCCCTCCCC
GAGGGGCGGG
GGGCGGGGAG
GGCGGGGAGG
GCCCCAGCCC
CAGCAGCAGC
CCGCCCCGCC
CCCCTCCCCG
CCCCTCCCCT
CCCGCCCCCG
CCCCTGCCCC
GCCCCCACCC
GCCCCCGCCC
GGGGAAGGGG
GAGGGGGCGG
CCCTCCCCGC
CCCTCCCCTC
GGGGTGGGGA
GGGAGGCGGG
TGGGGGCGGG
GGGTGGGGAG
GCCCCCAGCC
AGCCCCGCCC
CGGGGCTGGG
CCCAGGCCCC
CCCGCCCGCC
CCCCAGGCCC
GGCGGCGGGG
GCCCCTGCCC
GGGGGCTGGG
CCCAGCCCCA
CCCCTCCCTC
CCGCCCCTCC
CGCCCCTCCC
CCCAGCCCAG
GGCGGGGCCT
GGGCCGGGGC
CGCCCCCGCC
GCCCAGCCCC
CAGGGCTGGG
TCCTCCTCCT
CCCCGCCCCA
CCCGCCCCCC
GCAGCAGCAG
GGCGGCGGCC
GGTGGGGAGG
CCGCCGCCTC
GGCGGGGCCG
GGGAGGGGGA
GGGTGGGGGT
GGGCGGCGGG
GCCCCACCCC
GGGAGGAGGC
CCGCCCCCGC
CACCCCCACC
CGGCCGCCGC
AGGGAGGGAG
CACACACACA
CCCCGCGCCC
CCGCCCGCCC
TTTTTTTTTT
GCCCCGCCCC
CCCCGCCCCC
CCCCCACCCC
CCCCTCCCCC
CCCCCTCCCC
GGCGGCGGCG
CCCCACCCCC
CCGCCGCCGC
GCCGCCGCCG
CCCCCGCCCC
GGCCCCGCCC
GGGGCTGGGG
GGGAGGGGGC
CCTCCCTCCC
TCCCCTCCCC
GGAGGAGGAG
GGGAGGGGAG
CGGGGCGGGG
CCCCGCCCCT
GGGCTGGGGG
CCTCCTCCTC
CCCTCCCTCC
GGGGAGGAGG
CCCACCCCCA
GGGAGGAGGG
GCCCCTCCCC
CCCCCCACCC
GCGGGGCGGG
GGAGGGGAGG
CGCCCCGCCC
CCCCACCCCA
GGAGGAGGGG
TGGGGGAGGG
CGCCCCCTCC
TCCCCGCCCC
CCCGCCCCCT
CCCCGCCTCC
CCCCTCCCCA
GGGGCCGGGG
GGGGAGGGAG
CCCGCCCCTC
CTCCCCGCCC
CCTCCCCGCC
GGGCTGGGGC
GCTGCTGCTG
GGCGGGGCGG
CGGGGAGGGG
AGGGGAGGGG
CGGGGGCGGG
GGGGCAGGGG
GGGTGGGGGC
GGGCGGGGGC
CCCCTTCCCC
CCGCCCCCTC
GCGGGGAGGG
GAGGGGAGGG
TCCCCACCCC
CCCGCCTCCC
CCCGCCCCCA
CTCCCCACCC
GGCTGGGGGC
GGGCGGGGCT
CCCAGCCCCG
GGGGCCTGGG
GGCGGGCGGG
GGGCCTGGGG
CCCCGCCGCC
GGGCAGGGGC
CCCAGCCCCC
TGGGGCTGGG
GAGGGAGGGG
GGAGGGGCGG
GGGAGGGGCG
CTGGGCTGGG
AGGCCCCGCC
GCCCCGGCCC
GGCGGGGGCG
GGGGCTGGGC
CCCAGCCCTG
AGGAGGAGGA
TGGGGCGGGG
GGGGGGCGGG
CTGCTGCTGC
GGCCGCCGCC
CCTCCCCACC
GAGGCGGCGG
CGGCCCCGCC
TCCCCCTCCC
ACCCCCACCC
CCCGCCGCCC
GGGGTGGGGC
GCCTCCTCCC
GCGGGGGCGG
GGTGGGGGTG
GCGGCGGCCG
CTCCCTCCCT
TGTGTGTGTG
GGGCGCGGGG
GGGCGGGCGG
";
    $tmp =~ s/^\s+//s;
    $tmp =~ s/\s+$//s;
    my @repeats = split /\s+/, $tmp;
    return @repeats;
}

1;
