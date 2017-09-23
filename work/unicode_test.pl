use Encode;

try("\x3\xbc");

binmode STDOUT, ":utf8";
try2(0x3bc);
print "\x{3bc}\n";

sub try {
    my ($foo) = @_;
    Encode::from_to($foo, "UCS-2", "utf8");
    print "$foo\n";
}

sub try2 {
    my ($foo) = @_;
    my $goo = pack("U", $foo);
    print "$goo\n";
}
