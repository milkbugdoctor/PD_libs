#!/usr/local/install/ActivePerl/ActivePerl-5.10.0.1004-x86_64-EL4/bin/activeperl

# Needleman-Wunsch and Smith-Waterman alignment algorithms with
# graphic display of the dynamic programming matrix and traceback.
# Linear and affine gap costs.

# Peter Sestoft, Royal Veterinary and Agricultural University, Denmark
# Reference: http://www.dina.kvl.dk/~sestoft/bsa.html
# sestoft@dina.kvl.dk * 2003-04-19, 2003-05-04, 2003-08-25, 2003-10-16
#
# modified by Fred Long, Sidney Kimmel Cancer Center, San Diego, CA, U.S.A.
# flong@skcc.org * 2009-03-02

use strict;
use warnings;
no warnings 'recursion';

require 'align_string.pl';

package sestoft_align;

# ----------------------------------------------------------------------
# Global constants

# The traceback matrices are indexed by (direction, row, column).

my @DIR = (1, 2, 3);
my $STOP = 0;

# Directions in the linear (2D) traceback: 
# 0=stop; 1=from North (above); 2=from Northwest; 3=from West (left)
my ($FROMN, $FROMNW, $FROMW) = @DIR;

# Directions in the affine (3D) traceback: 
my ($FROMM, $FROMIX, $FROMIY) = @DIR;

# Minus infinity

my $minusInf = -2111111111;     # Representable in 32 bits 2's compl.

# Color codes for the traceback
my ($RED, $BLUE, $GREEN) = (1, 2, 3);

# ----------------------------------------------------------------------
# The Needleman-Wunsch global alignment algorithm, linear gap costs
# Input: The sequences $x and $y to align
# Output: references to the F and B matrices, and the aligned sequences

sub globalAlignLinear {
  my ($matrix, $x, $y, $e) = @_;            # By ref, val, val
  matrix_check($matrix, $x, $y);
  my ($n, $m) = (length($x), length($y));
  # The dynamic programming matrix
  my @F; 
  for (my $j=0; $j<=$m; $j++) {
    $F[$j] = [(0) x ($n+1)];
  }
  # The traceback matrix
  my @B; 
  foreach my $dir (@DIR) {
    for (my $j=0; $j<=$m; $j++) {
      $B[$dir][$j] = [(0) x ($n+1)];
    }
  }
  # Initialize upper and left-hand borders of F and B matrices
  for (my $i=1; $i<=$n; $i++) {
    $F[0][$i] = -$e * $i;
    $B[$FROMW][0][$i] = $RED;
  }
  for (my $j=1; $j<=$m; $j++) {
    $F[$j][0] = -$e * $j;
    $B[$FROMN][$j][0] = $RED;
  }
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      my $s = &score($matrix, substr($x, $i-1, 1), substr($y, $j-1, 1));
      my $val = &max($F[$j-1][$i-1]+$s, 
                     $F[$j][$i-1]-$e, 
                     $F[$j-1][$i]-$e);
      $F[$j][$i] = $val;
      # Record all traceback directions
      if ($val == $F[$j-1][$i-1]+$s) {
        $B[$FROMNW][$j][$i] = $RED;
      } 
      if ($val == $F[$j][$i-1]-$e) {
        $B[$FROMW][$j][$i] = $RED;
      } 
      if ($val == $F[$j-1][$i]-$e) {
        $B[$FROMN][$j][$i] = $RED;
      } 
    }
  }
  &markReachable2(\@B, $n, $m);
  my $result = { };
  $result->{F} = \@F;
  $result->{B} = \@B;
  $result->{xmax} = $n;
  $result->{ymax} = $m;
  ($result->{xalign}, $result->{yalign}, $result->{xmin}, $result->{ymin}) = &traceback2($x, $y, \@B, $n, $m);
  return $result;
}

# ----------------------------------------------------------------------
# The Smith-Waterman local alignment algorithm, linear gap costs
# Input: The sequences $x and $y to align
# Output: references to the F and B matrices, and the aligned sequences

sub localAlignLinear {
  my ($matrix, $x, $y, $e) = @_;            # By ref, val, val
  matrix_check($matrix, $x, $y);
  my ($n, $m) = (length($x), length($y));
  # The dynamic programming matrix; also correctly initializes borders
  my @F; 
  for (my $j=0; $j<=$m; $j++) {
    $F[$j] = [(0) x ($n+1)];
  }
  # The traceback matrix; also correctly initializes borders
  my @B; 
  foreach my $dir (@DIR) {
    for (my $j=0; $j<=$m; $j++) {
      $B[$dir][$j] = [($STOP) x ($n+1)];
    }
  }
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      my $s = &score($matrix, substr($x, $i-1, 1), substr($y, $j-1, 1));
      my $val = &max(0, 
                     $F[$j-1][$i-1]+$s, 
                     $F[$j][$i-1]-$e, 
                     $F[$j-1][$i]-$e);
      $F[$j][$i] = $val;
      # Record all traceback directions (none if we restart at score 0):
      if ($val == $F[$j-1][$i-1]+$s) {
        $B[$FROMNW][$j][$i] = $RED;
      } 
      if ($val == $F[$j][$i-1]-$e) {
        $B[$FROMW][$j][$i] = $RED;
      } 
      if ($val == $F[$j-1][$i]-$e) {
        $B[$FROMN][$j][$i] = $RED;
      } 
    }
  }
  # Find maximal score in matrix
  my $vmax = 0;
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      $vmax = &max($vmax, $F[$j][$i]);
    }
  }  
  my ($jmax, $imax) = (0, 0);
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      if ($vmax == $F[$j][$i]) {
        &markReachable2(\@B, $i, $j);
        $jmax = $j;
        $imax = $i;
      }
    }
  }  
  my $result = { };
  $result->{F} = \@F;
  $result->{B} = \@B;
  $result->{xmax} = $imax;
  $result->{ymax} = $jmax;
  ($result->{xalign}, $result->{yalign}, $result->{xmin}, $result->{ymin}) = &traceback2($x, $y, \@B, $imax, $jmax);
  return $result;
}

# ----------------------------------------------------------------------
# Common subroutines for linear gap cost routines

# Reconstruct the alignment from the traceback, backwards, from ($i, $j)

sub traceback2 {
  my ($x, $y, $B, $i, $j) = @_;         # B by reference
  my ($xAlign, $yAlign) = ("", "");
  while ($$B[$FROMN][$j][$i] || $$B[$FROMW][$j][$i] || $$B[$FROMNW][$j][$i]) {
    if ($$B[$FROMN][$j][$i]) {
      $$B[$FROMN][$j][$i] = $GREEN;
      $xAlign .= "-"; 
      $yAlign .= substr($y, $j-1, 1);
      $j--;
    } elsif ($$B[$FROMW][$j][$i]) {
      $$B[$FROMW][$j][$i] = $GREEN;
      $xAlign .= substr($x, $i-1, 1);
      $yAlign .= "-"; 
      $i--;
    } elsif ($$B[$FROMNW][$j][$i]) {
      $$B[$FROMNW][$j][$i] = $GREEN;
      $xAlign .= substr($x, $i-1, 1);
      $yAlign .= substr($y, $j-1, 1);
      $i--; $j--;
    }
  }
  # Warning: these expressions cannot be inlined in the list
  $xAlign = reverse $xAlign;
  $yAlign = reverse $yAlign;
  return ($xAlign, $yAlign, $i+1, $j+1);
}

# Mark all traceback arrows reachable from a ($i, $j)

sub markReachable2 {
  my ($B, $i, $j) = @_;         # B by reference
  if ($$B[$FROMN][$j][$i] == $RED) {
    $$B[$FROMN][$j][$i] = $BLUE;
    &markReachable2($B, $i, $j-1);
  } 
  if ($$B[$FROMW][$j][$i] == $RED) {
    $$B[$FROMW][$j][$i] = $BLUE;
    &markReachable2($B, $i-1, $j);
  } 
  if ($$B[$FROMNW][$j][$i] == $RED) {
    $$B[$FROMNW][$j][$i] = $BLUE;
    &markReachable2($B, $i-1, $j-1);
  }
}

# ----------------------------------------------------------------------
# The Needleman-Wunsch global alignment algorithm, affine gap costs
# Input: The sequences $x and $y to align
# Output: references to the matrices M, Ix, Iy, B, and the aligned sequences

sub globalAlignAffine {
  my ($matrix, $x, $y, $d, $e) = @_;
  matrix_check($matrix, $x, $y);
  my ($n, $m) = (length($x), length($y));
  # Initialize upper and left-hand borders
  # M represent an aa/aa match; 
  # Ix represents insertions in x (gaps in y); 
  # Iy represents insertions in y (gaps in x); 
  # The traceback now points to the matrix (M, Ix, Iy) from which the
  # maximum was obtained: $FROMM=1, $FROMIX=2, $FROMIY=3
  # B[$dir][1] is the traceback for M; 
  # B[$dir][2] is the traceback for Ix; 
  # B[$dir][3] is the traceback for Iy
  my (@M, @Ix, @Iy, @B);
  $M[0][0] = 0;
  $Ix[0][0] = $Iy[0][0] = $minusInf;
  foreach my $dir (@DIR) {
    for (my $j=0; $j<=$m; $j++) {
      for (my $k=1; $k<=3; $k++) {
        $B[$dir][$k][$j] = [($STOP) x ($n+1)];
      }
    }
  }
  for (my $i=1; $i<=$n; $i++) {
    $Ix[0][$i] = - $d - $e * ($i-1);
    $B[$FROMIX][2][0][$i] = $RED;
    $Iy[0][$i] = $minusInf;
    $M[0][$i] = $minusInf;
  }
  for (my $j=1; $j<=$m; $j++) {
    $Iy[$j][0] = - $d - $e * ($j-1);
    $B[$FROMIY][3][$j][0] = $RED;
    $Ix[$j][0] = $minusInf;
    $M[$j][0] = $minusInf;
  }
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      my $s = &score($matrix, substr($x, $i-1, 1), substr($y, $j-1, 1));
      my $val = &max($M[$j-1][$i-1]+$s, 
                     $Ix[$j-1][$i-1]+$s, 
                     $Iy[$j-1][$i-1]+$s);
      $M[$j][$i] = $val;
      if ($val == $M[$j-1][$i-1]+$s) {
        $B[$FROMM][1][$j][$i] = $RED; 
      } 
      if ($val == $Ix[$j-1][$i-1]+$s) {
        $B[$FROMIX][1][$j][$i] = $RED; 
      } 
      if ($val == $Iy[$j-1][$i-1]+$s) {
        $B[$FROMIY][1][$j][$i] = $RED; 
      } 
      $val = &max($M[$j][$i-1]-$d, $Ix[$j][$i-1]-$e, $Iy[$j][$i-1]-$d);  
      $Ix[$j][$i] = $val;
      if ($val == $M[$j][$i-1]-$d) {
        $B[$FROMM][2][$j][$i] = $RED;
      } 
      if ($val == $Ix[$j][$i-1]-$e) {
        $B[$FROMIX][2][$j][$i] = $RED;
      } 
      if ($val == $Iy[$j][$i-1]-$d) {
        $B[$FROMIY][2][$j][$i] = $RED;
      }      
      $val = &max($M[$j-1][$i]-$d, $Iy[$j-1][$i]-$e, $Ix[$j-1][$i]-$d);  
      $Iy[$j][$i] = $val;
      if ($val == $M[$j-1][$i]-$d) {
        $B[$FROMM][3][$j][$i] = $RED;
      } 
      if ($val == $Iy[$j-1][$i]-$e) {
        $B[$FROMIY][3][$j][$i] = $RED;
      } 
      if ($val == $Ix[$j-1][$i]-$d) {
        $B[$FROMIX][3][$j][$i] = $RED;
      }      
    }
  }
  # Find the matrix (@M, @Ix or @Iy) whose ($m,$n) cell has highest score:
  my ($kmax, $vmax) = (1, $M[$m][$n]);
  if ($vmax < $Ix[$m][$n]) {
    $vmax = $Ix[$m][$n];
    $kmax = 2;
  }
  if ($vmax < $Iy[$m][$n]) {
    $vmax = $Iy[$m][$n];
    $kmax = 3;
  }
  if ($M[$m][$n] == $vmax) {
    &markReachable3(\@B, 1, $n, $m);
  }
  if ($Ix[$m][$n] == $vmax) {
    &markReachable3(\@B, 2, $n, $m);
  }
  if ($Iy[$m][$n] == $vmax) {
    &markReachable3(\@B, 3, $n, $m);
  }
  my $result;
  $result->{M} = \@M;
  $result->{B} = \@B;
  $result->{Ix} = \@Ix;
  $result->{Iy} = \@Iy;
  $result->{xmin} = 1;
  $result->{ymin} = 1;
  $result->{xmax} = $n;
  $result->{ymax} = $m;
  ($result->{xalign}, $result->{yalign}) = &traceback3($x, $y, \@B, $kmax, $n, $m);
  return $result;
}

# ----------------------------------------------------------------------
# The Smith-Waterman local alignment algorithm, affine gap costs
# Input: The sequences $x and $y to align
#         The gap_open and gap_extend penalties
# Output: Hash reference containing matrices M, Ix, Iy, B, and the aligned sequences

sub localAlignAffine {
  my ($matrix, $x, $y, $d, $e) = @_;
  matrix_check($matrix, $x, $y);
  my ($n, $m) = (length($x), length($y));
  # Initialize upper and left-hand borders
  # M represent an aa/aa match; 
  # Ix represents insertions in x (gaps in y); 
  # Iy represents insertions in y (gaps in x); 
  # The traceback now points to the matrix (M, Ix, Iy) from which the
  # maximum was obtained: $FROMM=1, $FROMIX=2, $FROMIY=3
  # B[$dir][1] is the traceback for M; 
  # B[$dir][2] is the traceback for Ix; 
  # B[$dir][3] is the traceback for Iy
  my (@M, @Ix, @Iy, @B);
  for (my $j=0; $j<=$m; $j++) {
    $M[$j] = [(0) x ($n+1)];
    $Ix[$j] = [($minusInf) x ($n+1)];
    $Iy[$j] = [($minusInf) x ($n+1)];
  }
  # The traceback matrix; also correctly initializes borders
  foreach my $dir (@DIR) {
    for (my $j=0; $j<=$m; $j++) {
      for (my $k=1; $k<=3; $k++) {
        $B[$dir][$k][$j] = [($STOP) x ($n+1)];
      }
    }
  }
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      my $s = &score($matrix, substr($x, $i-1, 1), substr($y, $j-1, 1));
      my $val = &max(0, 
                     $M[$j-1][$i-1]+$s, 
                     $Ix[$j-1][$i-1]+$s, 
                     $Iy[$j-1][$i-1]+$s);
      $M[$j][$i] = $val;
      if ($val == $M[$j-1][$i-1]+$s) {
        $B[$FROMM][1][$j][$i] = $RED; 
      } 
      if ($val == $Ix[$j-1][$i-1]+$s) {
        $B[$FROMIX][1][$j][$i] = $RED; 
      } 
      if ($val == $Iy[$j-1][$i-1]+$s) {
        $B[$FROMIY][1][$j][$i] = $RED; 
      } 
      $val = &max($M[$j][$i-1]-$d, $Ix[$j][$i-1]-$e, $Iy[$j][$i-1]-$d);  
      $Ix[$j][$i] = $val;
      if ($val == $M[$j][$i-1]-$d) {
        $B[$FROMM][2][$j][$i] = $RED;
      } 
      if ($val == $Ix[$j][$i-1]-$e) {
        $B[$FROMIX][2][$j][$i] = $RED;
      } 
      if ($val == $Iy[$j][$i-1]-$d) {
        $B[$FROMIY][2][$j][$i] = $RED;
      }      
      $val = &max($M[$j-1][$i]-$d, $Iy[$j-1][$i]-$e, $Ix[$j-1][$i]-$d);  
      $Iy[$j][$i] = $val;
      if ($val == $M[$j-1][$i]-$d) {
        $B[$FROMM][3][$j][$i] = $RED;
      } 
      if ($val == $Iy[$j-1][$i]-$e) {
        $B[$FROMIY][3][$j][$i] = $RED;
      } 
      if ($val == $Ix[$j-1][$i]-$d) {
        $B[$FROMIX][3][$j][$i] = $RED;
      }      
    }
  }
  # Find maximal score in matrices
  my $vmax = 0;
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      $vmax = &max($vmax, $M[$j][$i], $Ix[$j][$i], $Iy[$j][$i]);
    }
  }  
  my ($kmax, $jmax, $imax) = (0, 0);
  for (my $i=1; $i<=$n; $i++) {
    for (my $j=1; $j<=$m; $j++) {
      if ($vmax == $M[$j][$i]) {
        &markReachable3(\@B, 1, $i, $j);
        $kmax = 1;
        $jmax = $j;
        $imax = $i;
      }
      if ($vmax == $Ix[$j][$i]) {
        &markReachable3(\@B, 2, $i, $j);
        $kmax = 2;
        $jmax = $j;
        $imax = $i;
      }
      if ($vmax == $Iy[$j][$i]) {
        &markReachable3(\@B, 3, $i, $j);
        $kmax = 3;
        $jmax = $j;
        $imax = $i;
      }
    }
  }  
  my $result;
  $result->{M} = \@M;
  $result->{B} = \@B;
  $result->{Ix} = \@Ix;
  $result->{Iy} = \@Iy;
  $result->{xmax} = $imax;
  $result->{ymax} = $jmax;
  ($result->{xalign}, $result->{yalign}, $result->{xmin}, $result->{ymin}) = &traceback3($x, $y, \@B, $kmax, $imax, $jmax);
  return $result;
}

# ------------------------------------------------------------
# Common subroutines for affine gap cost alignment
# Reconstruct the alignment from the traceback, backwards, 
# and mark green the path actually taken

sub traceback3 {
  my ($x, $y, $B, $k, $i, $j) = @_;   # B by reference
  my ($xAlign, $yAlign) = ("", "");
  while ($$B[$FROMM][$k][$j][$i] != 0 
         || $$B[$FROMIX][$k][$j][$i] != 0 
         || $$B[$FROMIY][$k][$j][$i] != 0) {
    my $nextk;
    # Colour green the path that was actually taken
    if ($$B[$FROMIY][$k][$j][$i]) {
      $$B[$FROMIY][$k][$j][$i] = $GREEN;
      $nextk = 3;       # From Iy
    } elsif ($$B[$FROMIX][$k][$j][$i]) {
      $$B[$FROMIX][$k][$j][$i] = $GREEN;
      $nextk = 2;       # From Ix
    } elsif ($$B[$FROMM][$k][$j][$i]) {
      $$B[$FROMM][$k][$j][$i] = $GREEN;
      $nextk = 1;       # From M
    } 
    if ($k == 1) {              # We're in the M matrix
      $xAlign .= substr($x, $i-1, 1);
      $yAlign .= substr($y, $j-1, 1);
      $i--; $j--;
    } elsif ($k == 2) {         # We're in the Ix matrix
      $xAlign .= substr($x, $i-1, 1);
      $yAlign .= "-"; 
      $i--;
    } elsif ($k == 3) {         # We're in the Iy matrix
      $xAlign .= "-"; 
      $yAlign .= substr($y, $j-1, 1);
      $j--;
    }       
    $k = $nextk;
  }
  # Warning: these expressions cannot be inlined in the list
  $xAlign = reverse $xAlign;
  $yAlign = reverse $yAlign;
  return ($xAlign, $yAlign, $i+1, $j+1);
}


# Mark blue all (affine) traceback arrows reachable from ($k, $i, $j)

sub markReachable3 {
  my ($B, $k, $i, $j) = @_;             # B by reference
  foreach my $dir (@DIR) {
    if ($$B[$dir][$k][$j][$i] == $RED) {
      $$B[$dir][$k][$j][$i] = $BLUE;
      if ($k == 1) {                    # We're in the M matrix
        &markReachable3($B, $dir, $i-1, $j-1);
      } elsif ($k == 2) {               # We're in the Ix matrix
        &markReachable3($B, $dir, $i-1, $j);
      } elsif ($k == 3) {               # We're in the Iy matrix
        &markReachable3($B, $dir, $i,   $j-1);
      }
    }
  }
}

sub matrix_check {
    my ($matrix, @strings) = @_;
    my %symbols;
    for my $string (@strings) {
        for my $sym (split //, $string) {
            $symbols{$sym} = 1;
        }
    }
    for my $i (keys %symbols) {
        for my $j (keys %symbols) {
	    if (! defined score($matrix, uc($i), uc($j))) {
		die "pair ($i, $j) is undefined in scoring matrix";
            }
        }
    }
}

########################################################
#   The following originally came from Constants.pm    #
########################################################

# The DNA nucleotides, the amino acids, and the standard genetic code.
# Here encapsulated in a package.
# KVL Biolinux * sestoft@dina.kvl.dk * 2002
#
# modified by Fred Long, Sidney Kimmel Cancer Center, San Diego, CA, U.S.A.
# flong@skcc.org * 2009-03-02

our %matrix;
           
# The BLOSUM45 amino acid substitution matrix

$matrix{blosum45} = create_matrix(<<TEXT);
#  Matrix made by matblas from blosum45.iij
#  * column uses minimum score
#  BLOSUM Clustered Scoring Matrix in 1/3 Bit Units
#  Blocks Database = /data/blocks_5.0/blocks.dat
#  Cluster Percentage: >= 45
#  Entropy =   0.3795, Expected =  -0.2789
   A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  B  Z  X  *
A  5 -2 -1 -2 -1 -1 -1  0 -2 -1 -1 -1 -1 -2 -1  1  0 -2 -2  0 -1 -1 -1 -5
R -2  7  0 -1 -3  1  0 -2  0 -3 -2  3 -1 -2 -2 -1 -1 -2 -1 -2 -1  0 -1 -5
N -1  0  6  2 -2  0  0  0  1 -2 -3  0 -2 -2 -2  1  0 -4 -2 -3  4  0 -1 -5
D -2 -1  2  7 -3  0  2 -1  0 -4 -3  0 -3 -4 -1  0 -1 -4 -2 -3  5  1 -1 -5
C -1 -3 -2 -3 12 -3 -3 -3 -3 -3 -2 -3 -2 -2 -4 -1 -1 -5 -3 -1 -2 -3 -1 -5
Q -1  1  0  0 -3  6  2 -2  1 -2 -2  1  0 -4 -1  0 -1 -2 -1 -3  0  4 -1 -5
E -1  0  0  2 -3  2  6 -2  0 -3 -2  1 -2 -3  0  0 -1 -3 -2 -3  1  4 -1 -5
G  0 -2  0 -1 -3 -2 -2  7 -2 -4 -3 -2 -2 -3 -2  0 -2 -2 -3 -3 -1 -2 -1 -5
H -2  0  1  0 -3  1  0 -2 10 -3 -2 -1  0 -2 -2 -1 -2 -3  2 -3  0  0 -1 -5
I -1 -3 -2 -4 -3 -2 -3 -4 -3  5  2 -3  2  0 -2 -2 -1 -2  0  3 -3 -3 -1 -5
L -1 -2 -3 -3 -2 -2 -2 -3 -2  2  5 -3  2  1 -3 -3 -1 -2  0  1 -3 -2 -1 -5
K -1  3  0  0 -3  1  1 -2 -1 -3 -3  5 -1 -3 -1 -1 -1 -2 -1 -2  0  1 -1 -5
M -1 -1 -2 -3 -2  0 -2 -2  0  2  2 -1  6  0 -2 -2 -1 -2  0  1 -2 -1 -1 -5
F -2 -2 -2 -4 -2 -4 -3 -3 -2  0  1 -3  0  8 -3 -2 -1  1  3  0 -3 -3 -1 -5
P -1 -2 -2 -1 -4 -1  0 -2 -2 -2 -3 -1 -2 -3  9 -1 -1 -3 -3 -3 -2 -1 -1 -5
S  1 -1  1  0 -1  0  0  0 -1 -2 -3 -1 -2 -2 -1  4  2 -4 -2 -1  0  0 -1 -5
T  0 -1  0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -1 -1  2  5 -3 -1  0  0 -1 -1 -5
W -2 -2 -4 -4 -5 -2 -3 -2 -3 -2 -2 -2 -2  1 -3 -4 -3 15  3 -3 -4 -2 -1 -5
Y -2 -1 -2 -2 -3 -1 -2 -3  2  0  0 -1  0  3 -3 -2 -1  3  8 -1 -2 -2 -1 -5
V  0 -2 -3 -3 -1 -3 -3 -3 -3  3  1 -2  1  0 -3 -1  0 -3 -1  5 -3 -3 -1 -5
B -1 -1  4  5 -2  0  1 -1  0 -3 -3  0 -2 -3 -2  0  0 -4 -2 -3  4  2 -1 -5
Z -1  0  0  1 -3  4  4 -2  0 -3 -2  1 -1 -3 -1  0 -1 -2 -2 -3  2  4 -1 -5
X -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -5
* -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5  1
TEXT

# The BLOSUM50 amino acid substitution matrix

$matrix{blosum50} = create_matrix(<<TEXT);
#  Matrix made by matblas from blosum50.iij
#  * column uses minimum score
#  BLOSUM Clustered Scoring Matrix in 1/3 Bit Units
#  Blocks Database = /data/blocks_5.0/blocks.dat
#  Cluster Percentage: >= 50
#  Entropy =   0.4808, Expected =  -0.3573
   A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  B  Z  X  *
A  5 -2 -1 -2 -1 -1 -1  0 -2 -1 -2 -1 -1 -3 -1  1  0 -3 -2  0 -2 -1 -1 -5
R -2  7 -1 -2 -4  1  0 -3  0 -4 -3  3 -2 -3 -3 -1 -1 -3 -1 -3 -1  0 -1 -5
N -1 -1  7  2 -2  0  0  0  1 -3 -4  0 -2 -4 -2  1  0 -4 -2 -3  4  0 -1 -5
D -2 -2  2  8 -4  0  2 -1 -1 -4 -4 -1 -4 -5 -1  0 -1 -5 -3 -4  5  1 -1 -5
C -1 -4 -2 -4 13 -3 -3 -3 -3 -2 -2 -3 -2 -2 -4 -1 -1 -5 -3 -1 -3 -3 -2 -5
Q -1  1  0  0 -3  7  2 -2  1 -3 -2  2  0 -4 -1  0 -1 -1 -1 -3  0  4 -1 -5
E -1  0  0  2 -3  2  6 -3  0 -4 -3  1 -2 -3 -1 -1 -1 -3 -2 -3  1  5 -1 -5
G  0 -3  0 -1 -3 -2 -3  8 -2 -4 -4 -2 -3 -4 -2  0 -2 -3 -3 -4 -1 -2 -2 -5
H -2  0  1 -1 -3  1  0 -2 10 -4 -3  0 -1 -1 -2 -1 -2 -3  2 -4  0  0 -1 -5
I -1 -4 -3 -4 -2 -3 -4 -4 -4  5  2 -3  2  0 -3 -3 -1 -3 -1  4 -4 -3 -1 -5
L -2 -3 -4 -4 -2 -2 -3 -4 -3  2  5 -3  3  1 -4 -3 -1 -2 -1  1 -4 -3 -1 -5
K -1  3  0 -1 -3  2  1 -2  0 -3 -3  6 -2 -4 -1  0 -1 -3 -2 -3  0  1 -1 -5
M -1 -2 -2 -4 -2  0 -2 -3 -1  2  3 -2  7  0 -3 -2 -1 -1  0  1 -3 -1 -1 -5
F -3 -3 -4 -5 -2 -4 -3 -4 -1  0  1 -4  0  8 -4 -3 -2  1  4 -1 -4 -4 -2 -5
P -1 -3 -2 -1 -4 -1 -1 -2 -2 -3 -4 -1 -3 -4 10 -1 -1 -4 -3 -3 -2 -1 -2 -5
S  1 -1  1  0 -1  0 -1  0 -1 -3 -3  0 -2 -3 -1  5  2 -4 -2 -2  0  0 -1 -5
T  0 -1  0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -2 -1  2  5 -3 -2  0  0 -1  0 -5
W -3 -3 -4 -5 -5 -1 -3 -3 -3 -3 -2 -3 -1  1 -4 -4 -3 15  2 -3 -5 -2 -3 -5
Y -2 -1 -2 -3 -3 -1 -2 -3  2 -1 -1 -2  0  4 -3 -2 -2  2  8 -1 -3 -2 -1 -5
V  0 -3 -3 -4 -1 -3 -3 -4 -4  4  1 -3  1 -1 -3 -2  0 -3 -1  5 -4 -3 -1 -5
B -2 -1  4  5 -3  0  1 -1  0 -4 -4  0 -3 -4 -2  0  0 -5 -3 -4  5  2 -1 -5
Z -1  0  0  1 -3  4  5 -2  0 -3 -3  1 -1 -4 -1  0 -1 -2 -2 -3  2  5 -1 -5
X -1 -1 -1 -1 -2 -1 -1 -2 -1 -1 -1 -1 -1 -2 -2 -1  0 -3 -1 -1 -1 -1 -1 -5
* -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5 -5  1
TEXT

# The BLOSUM62 amino acid substitution matrix

$matrix{blosum62} = create_matrix(<<TEXT);
#  Matrix made by matblas from blosum62.iij
#  * column uses minimum score
#  BLOSUM Clustered Scoring Matrix in 1/2 Bit Units
#  Blocks Database = /data/blocks_5.0/blocks.dat
#  Cluster Percentage: >= 62
#  Entropy =   0.6979, Expected =  -0.5209
   A  R  N  D  C  Q  E  G  H  I  L  K  M  F  P  S  T  W  Y  V  B  Z  X  *
A  4 -1 -2 -2  0 -1 -1  0 -2 -1 -1 -1 -1 -2 -1  1  0 -3 -2  0 -2 -1 -1 -4
R -1  5  0 -2 -3  1  0 -2  0 -3 -2  2 -1 -3 -2 -1 -1 -3 -2 -3 -1  0 -1 -4
N -2  0  6  1 -3  0  0  0  1 -3 -3  0 -2 -3 -2  1  0 -4 -2 -3  3  0 -1 -4
D -2 -2  1  6 -3  0  2 -1 -1 -3 -4 -1 -3 -3 -1  0 -1 -4 -3 -3  4  1 -1 -4
C  0 -3 -3 -3  9 -3 -4 -3 -3 -1 -1 -3 -1 -2 -3 -1 -1 -2 -2 -1 -3 -3 -1 -4
Q -1  1  0  0 -3  5  2 -2  0 -3 -2  1  0 -3 -1  0 -1 -2 -1 -2  0  3 -1 -4
E -1  0  0  2 -4  2  5 -2  0 -3 -3  1 -2 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4
G  0 -2  0 -1 -3 -2 -2  6 -2 -4 -4 -2 -3 -3 -2  0 -2 -2 -3 -3 -1 -2 -1 -4
H -2  0  1 -1 -3  0  0 -2  8 -3 -3 -1 -2 -1 -2 -1 -2 -2  2 -3  0  0 -1 -4
I -1 -3 -3 -3 -1 -3 -3 -4 -3  4  2 -3  1  0 -3 -2 -1 -3 -1  3 -3 -3 -1 -4
L -1 -2 -3 -4 -1 -2 -3 -4 -3  2  4 -2  2  0 -3 -2 -1 -2 -1  1 -4 -3 -1 -4
K -1  2  0 -1 -3  1  1 -2 -1 -3 -2  5 -1 -3 -1  0 -1 -3 -2 -2  0  1 -1 -4
M -1 -1 -2 -3 -1  0 -2 -3 -2  1  2 -1  5  0 -2 -1 -1 -1 -1  1 -3 -1 -1 -4
F -2 -3 -3 -3 -2 -3 -3 -3 -1  0  0 -3  0  6 -4 -2 -2  1  3 -1 -3 -3 -1 -4
P -1 -2 -2 -1 -3 -1 -1 -2 -2 -3 -3 -1 -2 -4  7 -1 -1 -4 -3 -2 -2 -1 -1 -4
S  1 -1  1  0 -1  0  0  0 -1 -2 -2  0 -1 -2 -1  4  1 -3 -2 -2  0  0 -1 -4
T  0 -1  0 -1 -1 -1 -1 -2 -2 -1 -1 -1 -1 -2 -1  1  5 -2 -2  0 -1 -1 -1 -4
W -3 -3 -4 -4 -2 -2 -3 -2 -2 -3 -2 -3 -1  1 -4 -3 -2 11  2 -3 -4 -3 -1 -4
Y -2 -2 -2 -3 -2 -1 -2 -3  2 -1 -1 -2 -1  3 -3 -2 -2  2  7 -1 -3 -2 -1 -4
V  0 -3 -3 -3 -1 -2 -2 -3 -3  3  1 -2  1 -1 -2 -2  0 -3 -1  4 -3 -2 -1 -4
B -2 -1  3  4 -3  0  1 -1  0 -3 -4  0 -3 -3 -2  0 -1 -4 -3 -3  4  1 -1 -4
Z -1  0  0  1 -3  3  4 -2  0 -3 -3  1 -1 -3 -1  0 -1 -3 -2 -2  1  4 -1 -4
X -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -4
* -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4 -4  1
TEXT

# The score of a pair of amino acids in a given matrix

sub score {
  my ($matrix, $aa1, $aa2) = @_;	# By ref, val, val
  return $$matrix[ord(uc($aa1))][ord(uc($aa2))];
}

# The maximum of a list of numbers

sub max {
  die "can't take max of empty list" if @_ == 0;
  my $res = pop @_;
  foreach (@_) {
    if ($_ > $res) {
      $res = $_;
    }
  }
  return $res;
}

# Make random DNA sequence of specified length

sub randomdna {
  my ($len) = @_;	  # length of sequence to generate
  my $dna = "";
  foreach (1..$len) {
    my $p = rand(4);
    $dna = $dna . substr("ACGT", $p, 1);
  }
  return $dna;
}

sub main::load_matrix {
    my ($filename) = @_;
    my $fd;
    open($fd, $filename) || return undef;
    my $str;
    while (<$fd>) {
	$str .= $_;
    }
    return create_matrix($str);
}

sub create_matrix {
    my ($str) = @_;
    $str = uc($str); # convert to uppercase
    my $row = 0;
    my (%hash, @matrix, @letters);
    my $num_columns = 0;
    for (split /\n/, $str) {
	next if /^#/;
	s/#.*//;
	s/^\s+//;
	s/\s+$//;
	my @line = split /\s+/;
	if ($row == 0) {
	    $num_columns = @line;
	    @letters = @line;
	    for (my $i = 1; $i <= @line; $i++) {
		$hash{$line[$i - 1]} = $i;
	    }
	}
	else {
	    if (@line == $num_columns + 1) {
		my $letter = shift(@line);
		if (!defined($hash{$letter})) {
		    die "bad starting column [$letter]";
		}
		if ($hash{$letter} != $row) {
		    die "found starting column [$letter] out of order";
		}
	    }
	    if (@line == $num_columns) {
		my $r = $letters[$row - 1];
		for my $col (1 .. @line) {
		    my $c = $letters[$col - 1];
		    $matrix[ord($r)][ord($c)] = $line[$col - 1];
		}
	    }
	}
	$row++;
    }
    for my $i (keys %hash) {
	my $ii = ord($i);
	for my $j (keys %hash) {
	    my $jj = ord($j);
	    if (!defined($matrix[$ii][$jj])) {
		die "\$matrix[$i][$j] is not defined";
	    }
	    if (!defined($matrix[$jj][$ii])) {
		die "\$matrix[$j][$i] is not defined";
	    }
	    if ($matrix[$ii][$jj] != $matrix[$jj][$ii]) {
		die "matrix not symmetric at $i and $j";
	    }
	}
    }
    return \@matrix;
}

sub main::create_simple_matrix {
    my ($match, $mismatch, @strings) = @_;
    my %symbols;
    my @matrix;
    for my $string (@strings) {
	for my $sym (split //, $string) {
	    $symbols{$sym} = 1;
	}
    }
    for my $i (keys %symbols) {
	my $ii = ord($i);
	for my $j (keys %symbols) {
	    my $jj = ord($j);
	    if ($i eq $j) {
		$matrix[$ii][$jj] = $match;
	    }
	    else {
		$matrix[$ii][$jj] = $mismatch;
		$matrix[$jj][$ii] = $mismatch;
	    }
	}
    }
    return \@matrix;
}

sub main::get_verbose_alignment_string {
    my ($hash) = @_;
    my $result = '';
    $result .= sprintf "%3d %s %-3d\n", $hash->{xmin}, $hash->{xalign}, $hash->{xmax};
    $result .= sprintf "%3d %s %-3d\n", $hash->{ymin}, $hash->{yalign}, $hash->{ymax};
    $result .= sprintf "align_string: %s\n", ::compute_alignment_string(
	$hash->{xalign}, $hash->{yalign});
    return $result;
}

#
#   kind = 'global' or 'local'
#
sub main::sestoft_align {
  my ($kind, $gap_open, $gap_extend, $matrix, $seq1, $seq2) = @_;
  if ($matrix eq '') {
    $matrix = $matrix{blosum62};
  }
  elsif ($matrix{$matrix} ne '') {
    $matrix = $matrix{$matrix};
  }
  if ($gap_open == $gap_extend) {
    if ($kind eq "global") { 
      return &globalAlignLinear($matrix, $seq1, $seq2, $gap_extend);
    } elsif ($kind eq "local") { 
      return &localAlignLinear($matrix, $seq1, $seq2, $gap_extend);
    }
  } else {
    if ($kind eq "global") { 
      return &globalAlignAffine($matrix, $seq1, $seq2, $gap_open, $gap_extend);
    } elsif ($kind eq "local") { 
      return &localAlignAffine($matrix, $seq1, $seq2, $gap_open, $gap_extend);
    }
  }
}

1;
