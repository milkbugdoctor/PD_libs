##############################################################################
#
#   dates.pl - Date functions for Perl 4
#
#   flong@sea.com
#
#   Fri Oct  8 17:12:47 PDT 1999
#
#   Copyright (c) 1999, Systems Engineering Associates; all rights reserved.
#
##############################################################################

use Carp;
require 'misc.pl';

##############################################################################
#
#   Notes:
#
#	Valid dates are in the format "m/d/y" or "m-d-y", where y >= 0.
#
#	The "Canonical Date Format" is "mm/dd/yyyy", where yyyy >= 1.
#
#	Many of the routines below convert dates to the canonical format,
#	since only canonical dates can be compared as strings.
#
#	For example, "1-2-99" and "01/02/1999" refer to the same date, but
#	a strings comparison would say that they are different.  Converting
#	them to the canonical format solves this problem.
#
##############################################################################

##############################################################################
#
#	Public routines.
#
##############################################################################

#
#	Convert string to Canonical Date Format.  Return "" if error.
#
#	Examples:
#		"01/01/01" -> "01/01/2001"
#		"1/1/0"    -> "1/1/2000"
#		"2/30/99"  -> ""
#		"2-1/99"   -> "02/01/1999"
#		"1231/99"  -> "12/31/1999"
#		"12311899" -> "12/31/1899"
#
sub _Date_fix {
	local($date) = @_;
	local(@date) = &_date($date);
	$date[2] = &fix_year($date[2]);
	$date = join('/', @date);
	return &Date_canonical($date);
}


#
#	Convert string to Canonical Date Format.  Die if error.
#
sub Date_fix {
	&_Date_fix($_[0]) || confess("Invalid date \"$_[0]\"");
}


#
#	Return month of given date in mm/yyyy format, "" if error.
#
sub _month {
	local(@date) = &_date(&_Date_fix($_[0]));
	return "" if @date != 3;
	return sprintf("%02d/%04d", $date[0], $date[2]);
}


#
#	Return month of given date in mm/yyyy format.  Die if error.
#
sub month {
	return &_month($_[0]) || confess("Invalid date \"$_[0]\"");
}


#
#	Perform arithmetic on date array, without year conversions or
#	validity checking.
#
sub date_add {
	local($month) = $_[0] + $_[3];
	local($day) = $_[1] + $_[4];
	local($year) = $_[2] + $_[5];
	local($done, $days, $now);
	do {
		$done = 1;
		while ($month > 12) {
			$month -= 12;
			$year++;
		}
		while ($month < 1) {
			$month += 12;
			$year--;
		}
		$days = &month_days($month, $year);
		if ($day > $days) {
			$day -= $days;
			$month++;
			$done = 0;
		}
		if ($day < 1) {
			if ($now) {
				$now = 0;
				$day += $days;
			}
			else {
				$month--;
				$now = 1;
			}
			$done = 0;
		}
	} until $done;
	($month, $day, $year);
}


#
#	Is it a leap year?  Requires "fixed" year.  0 != 2000.
#
sub leap {
	($_[0] % 400 == 0) || ($_[0] % 4 == 0 && $_[0] % 100 != 0);
}

#
#	How many days in this year?  Requires "fixed" year.  0 != 2000.
#
sub year_days {
	(&leap($_[0]) && 366) || 365;
}

#
#	How many days in this month (mm, yyyy)?
#
sub month_days {
	$_[0] == 1 && return 31;
	$_[0] == 2 && return 28 + &leap($_[1]);
	$_[0] == 3 && return 31;
	$_[0] == 4 && return 30;
	$_[0] == 5 && return 31;
	$_[0] == 6 && return 30;
	$_[0] == 7 && return 31;
	$_[0] == 8 && return 31;
	$_[0] == 9 && return 30;
	$_[0] == 10 && return 31;
	$_[0] == 11 && return 30;
	$_[0] == 12 && return 31;
	0;
}

#
#	Return negative, 0, or positive to compare dates.  Die if error.
#
sub Date_cmp { &date_cmp(&date($_[0]), &date($_[1])); }

#
#	Return them minimum from the list of dates.  Die if error.
#
sub Date_min {
	return &Date_fix($_[0]) if @_ == 1;
	return &Date_min(((&Date_cmp($_[0], $_[1]) < 0) ? $_[0] : $_[1]),
		@_[2..$#_]);
}

#
#	Return the maximum from the list of dates.  Die if error.
#
sub Date_max {
	return &Date_fix($_[0]) if @_ == 1;
	return &Date_max(((&Date_cmp($_[0], $_[1]) > 0) ? $_[0] : $_[1]),
		@_[2..$#_]);
}


#
#	Convert "m/d/yyyy" to "mm/dd/yyy", or "" if error.
#
sub Date_canonical {
	return '' if !($_[0] =~ m|\d+/\d+/\d\d\d\d+|);
	local($month, $day, $year) = &_date($_[0]);
	return '' if $day < 1 || $month < 1 || $year < 1;
	return '' if $month > 12;
	return '' if $day > &month_days($month, $year);
	return sprintf("%02d/%02d/%04d", $month, $day, $year);
}


#
#	Return number of days since 12/31/1899, "" if invalid date
#
sub _julian {
	local($date) = &_Date_fix($_[0]);
	return "" if $date eq "";
	local($month, $day, $year) = &_date($date);
	local($i, $days);
	$days = &year_start_day($year) - &year_start_day(1900);
	for ($i = 0; $i < $month; $i++) {
		$days += &month_days($i, $year);
	}
	$days += $day;
	return "$days";
}


#
#	Return number of days since 12/31/1899, with year conversion.
#	Die if error.
#
sub julian { return &_julian(&Date_fix($_[0])); }


#
#	Convert "julian day number" to gregorian date.
#	Return "" if date would be less than 1/1/0001.
#
sub _gregorian {
	return "" if !($_[0] =~ /\s*[-+]?\d+\s*/); # valid number?
	# get absolute 1-based julian day from 1/1/0001
	local($julian) = $_[0] + &year_start_day(1900) - 1;
	return "" if $julian < 1;
	# make a good guess at the year
	local($year) = int($julian / 365.2425) + 1;
	$year = 1 if $year < 1;
	while ($julian < year_start_day($year)) {
	    $year--;
	}
	while ($julian >= year_start_day($year + 1)) {
	    $year++;
	}
	# make $julian 1-based day offset from beg. of year
	$julian = $julian - &year_start_day($year) + 1;

	local($month) = 1;
	local($tmp, $i);
	while (($tmp = &month_days($month, $year)) < $julian) {
		$julian -= $tmp;
		$month++;
		if ($month > 12) {
			$month -= 12;
			$year++;
		}
	}
	return sprintf("%02d/%02d/%04d", $month, $julian, $year);
}


#
#	Convert to gregorian with error checking.
#
sub gregorian {
	&_gregorian($_[0]) || confess("Invalid day number \"$_[0]\"");
}


#
#	Return the first day of the month.
#
sub Month_first_day {
	local($month, $day, $year) = &date($_[0]);
	return &Date($month, 1, $year);
}


#
#	Return the last day of the month.
#
sub Month_last_day {
	local($month, $day, $year) = &date($_[0]);
	return &Date($month, &month_days($month, $year), $year);
}


#
#	Return today's date
#
sub today {
	local(@time) = localtime(time);
	$time[4]++;
	$time[5] += 1900; # don't change this, it's OK
	return "$time[4]/$time[3]/$time[5]";
}


#
#	Add months, days, or years to a date.
#
#	When adding months or years, the date is first automatically
#	converted to the first of the month.
#
#	E.g. &Add_day("3/1/00", -1)     is "02/29/2000"
#	     &Add_month("05/31/00", -1) is "04/01/2000"
#	     &Add_year("05/31/00", 1)   is "05/01/2001"
#
sub Date_add  { return &Date(&date_add(&date($_[0]), &_date_split($_[1]))); }
sub Add_day   { return &Date_add($_[0], "0/$_[1]/0"); }
sub Add_month { return &Date_add(&Month_first_day($_[0]), "$_[1]/0/0"); }
sub Add_year  { return &Date_add(&Month_first_day($_[0]), "0/0/$_[1]"); }


##############################################################################
#
#	For internal use only.
#
##############################################################################

#
#	Return the date as an array.  Return () if error.
#
sub _date {
	local($o) = '[^\d\n]';
	return ($1, $2, $3) if $_[0] =~ m|$o*(\d+)$o+(\d+)$o+(\d+)$o*|;
	return ($1, $2, $3) if $_[0] =~ m|$o*(\d\d)(\d\d)$o*(\d+)$o*|;
	return ();
}


#
#	Special purpose date split, allows negative numbers.
#
sub _date_split {
	local($num) = '\s*([-+]?\d+)\s*';
	return ($1, $2, $3) if $_[0] =~ m|$num/$num/$num|;
	return ();
}


#
#	Get Date string, no year conversion.
#
sub Date_join {
	local($result) = join('/', @_);
	confess("Invalid date \"$result\"") if $#_ < 2;
	return $result;
}


#
#	Get date array, with year conversion.  Die if error.
#
sub date { &_date(&Date_fix($_[0])); }


#
#	Get Date string from array, with year conversion.  Die if error.
#
sub Date { return &Date_fix(&Date_join(@_)); }

sub date_cmp {
	return ($_[2] - $_[5]) if $_[2] != $_[5];
	return ($_[0] - $_[3]) if $_[0] != $_[3];
	return ($_[1] - $_[4]) if $_[1] != $_[4];
	return 0;
}


sub date_min { (&date_cmp(@_) < 0) ? @_[0..2] : @_[3..5]; }


sub date_max { (&date_cmp(@_) > 0) ? @_[0..2] : @_[3..5]; }


#
#	Return 4-digit year using closest century, or "" if error.
#
sub fix_year {
	return "" if !($_[0] =~ /\d+/);
	if (length($_[0]) <= 2 && $_[0] >= 0) {
		local($today) = (&_date(&today()))[2];
		return "" if $today < 1900;
		local($year) = $today % 100;
		local($century) = $today - $year;
		local($start) = ($today + 50) % 100;
		return ($_[0] + 100 - $start) % 100 + $today - 50;
	}
	return sprintf("%04d", $_[0]);
}


sub year_start_day {
	local($i) = $_[0] - 1;
	365 * $i + int($i/400) + int($i/4) - int($i/100) + 1;
}

1;
