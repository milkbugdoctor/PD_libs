##############################################################################
#
#   floats.pl - Useful floating point and numeric routines
#
#   flong@sea.com
#
#   Tue Oct 26 13:31:52 PDT 1999
#
#   Copyright (c) 1999, Systems Engineering Associates; all rights reserved.
#
##############################################################################

#############################################################################
#
#	16-digit decimal routines
#
#############################################################################

require 'bigfloat.pl';

#
#	Round float to 16 digits.
#
sub to_16 {
	local($bigfloat'rnd_mode) = 'inf'; # round "out" towards -inf or +inf
	&fround($_[0] || 0, 16);
}

sub add_16 { &to_16(&fadd(&to_16($_[0]), &to_16($_[1]))); }

sub addto_16 { $_[0] = &add_16(@_); }

#############################################################################
#
#	Other numberic routines
#
#############################################################################

#
#	Convert the number into a string, preserving all significant digits.
#	(20 significant digits should be enough, for now.)
#
sub real {
	sprintf("%.20e", $_[0] + 0);
}

#
#	Round towards +infinity.  Adjust threshold with nudge factor.
#
sub round {
    local($val, $places, $nudge) = @_;
    if ($val > 0) {
	return sprintf("%.${places}f", $val + $nudge);
    }
    else {
	# do this to avoid -0.00
	local($offset) = int(-$val) + 1;
	$val = sprintf("%.${places}f", $val + $offset + $nudge) - $offset;
	return sprintf("%.${places}f", $val);
    }
}

#
#	 Round towards +infinity at threshold.
#
sub round_up { return &round(@_, .000000001); }

#
#	 Round towards -infinity at threshold.
#
sub round_down { return &round(@_, -.000000001); }

#
#	 Round towards zero at threshold.
#
sub round_in { ($_[0] > 0) ? &round_down(@_) : &round_up(@_); }

#
#	 Round away from zero at threshold.
#
sub round_out { ($_[0] > 0) ? &round_up(@_) : &round_down(@_); }

#
#	&zero($number, $tolerance);
#
sub zero {
	($_[0] > 0 && $_[0] < $_[1]) || ($_[0] < 0 && -$_[0] < $_[1]);
}

#
#	Return the absolute value.
#
sub abs {
	return $_[0] if $_[0] >= 0;
	return -$_[0];
}

#
#	Return the minimum of the values.
#
sub min {
	return $_[0] if @_ <= 1;
	return &min(($_[0] < $_[1]) ? $_[0] : $_[1], @_[2..$#_]);
}

#
#	Return the maximum of the values.
#
sub max {
	return $_[0] if @_ <= 1;
	return &max(($_[0] > $_[1]) ? $_[0] : $_[1], @_[2..$#_]);
}

sub add_commas {
	local($a, $b) = split(/\./, $_[0]);
	while ($a =~ s/(\d)(\d\d\d)([^\d]|$)/\1,\2\3/) { ; }
	$a .= ".$b" if $b ne "";
	return $a;
}

1;
