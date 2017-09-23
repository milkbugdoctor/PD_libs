package GD_stuff;

$PI = 3.14159265358979323846;
$PI_2 = 1.57079632679489661923;

use GD;
use GD::Polyline;

sub ::draw_string {
    my ($halign, $valign, $im, $color, $font, $size, $angle, $x, $y, $string,
	@rest) = @_;
    my @bounds = GD::Image->stringFT($color, $font, $size, $angle, $x, $y, $string, @rest);
    my $wid = $bounds[4] - $bounds[0];
    my $tall = $bounds[1] - $bounds[5];

    my $hack = 0;
    if ($halign eq 'center') {
	$x = $x - ($wid - $hack * $size)/2;
    }
    elsif ($halign eq 'right') {
	$x = $x - $wid;
    }
    if ($valign eq 'bottom') {
    }
    elsif ($valign eq 'top') {
	$y = $y + $size;
    }
    else {
	$y = $y + $size / 2;
    }

    return $im->stringFT($color, $font, $size, $angle, $x, $y, $string, @rest);
}

1;
