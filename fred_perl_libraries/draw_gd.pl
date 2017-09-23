package draw_gd;

my $debug = 0;

# radial_box xc yc start_angle end_angle radius len color [outline-color thickness]
# radial_line xc yc angle radius len color thick
# radial_text xc yc angle radius color size halign valign "text"

$PI = 3.14159265358979323846;
$PI_2 = 1.57079632679489661923;

$font = "/usr/local/lib/fonts/ttf/luxisb.ttf";

use GD;
use GD::Polyline;

$pixels = 4000;
$ypixels = $pixels * 5 / 4;
$scale = 105.0;
$xoffset = (1 - 100/$scale) / 2 * $pixels;
$yoffset = (1 - 100/$scale) / 2 * $pixels + ($ypixels - $pixels) / 2;

sub init_colors {
    my ($im) = @_;
    # allocate some colors
    %color_hash = (
	"red", 		$im->colorAllocate(255, 0, 0),
	"green",	$im->colorAllocate(0, 255, 0),
	"blue",		$im->colorAllocate(0, 0, 255),
	"black",	$im->colorAllocate(0, 0, 0),
	"grey",		$im->colorAllocate(128, 128, 128),
	"gray",		$im->colorAllocate(128, 128, 128),
	"no data",	$im->colorAllocate(255, 255, 255),
	"white",	$im->colorAllocate(255, 255, 255),
	"orange",	$im->colorAllocate(255, 128, 64),
	"pink",		$im->colorAllocate(255, 128, 128),
	"purple",	$im->colorAllocate(255, 0, 255)
    );
}

sub color {
    my ($c) = @_;
    return $color_hash{$c} if defined $color_hash{$c};
    if ($c =~ m|([\d.]+)[,/]\s*([\d.]+)[,/]\s*([\d.]+)|) {
	$color = $im->colorAllocate($1, $2, $3);
	die "Can't allocate color ($1, $2, $3)\n" if $color < 0;
	$color_hash{$c} = $color;
	return $color;
    }
    else {
	die "Unknown color '$c'\n";
    }
}

#
#    input: 0 - 1, starts at top and goes clockwise
#    output: 0 - 360 angle
#
sub get_angle {
    my @angles;
    for my $pos (@_) {
        push(@angles, $ang = 360 + ($pos * 360 - 90));
    }
    @angles = sort {$a <=> $b} @angles;
    return @angles;
}

sub scale_xy {
    my ($x, $y) = @_;
    $x = $xoffset + ($x / $scale) * $pixels;
    $y = $yoffset + ($y / $scale) * $pixels;
    return ($x, $y);
}

sub from_polar {
    my ($radius, $angle) = @_;
    $angle = $angle * 2 * $PI - $PI/2.0;
    $x = cos($angle) * ($radius) / $scale * $pixels / 2.0;
    $y = sin($angle) * ($radius) / $scale * $pixels / 2.0;
    return ($x, $y);
}

#
#   angle = 0 - 1
#
sub polar_to_cartesian {
    my ($radius, $angle) = @_;
    $angle = $angle * 2 * $PI - $PI/2.0;
    $x = cos($angle) * $radius;
    $y = sin($angle) * $radius;
    return ($x, $y);
}

sub len {
    my ($radius) = @_;
    my $len = $radius * $pixels / $scale;
    return $len;
}

sub create_dot_brush {
    my ($width, $color) = @_;
    # Create a brush at an angle
    my $brush = new GD::Image($width, $width);
    my $t = $brush->colorAllocate(1, 2, 3);
    my $c = $brush->colorAllocate(rgb($color));
    $brush->transparent($t);
    $brush->filledArc($width/2, $width/2, $width/2, $width/2, 0, 360, $c);
    return $brush;
}

sub rgb {
    if ($_[0] eq "red") 	{ return (255, 0, 0); }
    if ($_[0] eq "green")	{ return (0, 255, 0); }
    if ($_[0] eq "blue")	{ return (0, 0, 255); }
    if ($_[0] eq "black")	{ return (0, 0, 0); }
    if ($_[0] eq "grey")	{ return (128, 128, 128); }
    if ($_[0] eq "no data")	{ return (255, 255, 255); }
    if ($_[0] eq "white")	{ return (255, 255, 255); }
    if ($_[0] eq "orange")	{ return (255, 128, 64); }
    if ($_[0] eq "pink")	{ return (255, 128, 128); }
    if ($_[0] eq "purple")	{ return (255, 0, 255); }
    if ($_[0] =~ m|(\d+)[,/](\d+)[,/](\d+)|) {
	return ($1, $2, $3);
    }
    die "Unknown color '$_[0]'";
}

sub shift_text {
    my ($font, $size, $x, $y, $string, $halign, $valign) = @_;
    my @bounds = GD::Image->stringFT(gdBrushed, $font, $size, 0, $x, $y, $string);
    my $wid = $bounds[4] - $bounds[0];
    my $tall = $bounds[1] - $bounds[5];
    if ($halign eq 'center') {
	$x = $x - ($wid - .15 * $size)/2;
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
    return ($x, $y);
}

1;
