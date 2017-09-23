#!/usr/bin/perl -w

die "\nUsage: $0 file ...\n\n" unless @ARGV;

use strict;
use Spreadsheet::WriteExcel::Big;

my @files;
while (my $file = pop(@ARGV)) {
    my @expanded = <"${file}">;
    push(@files, @expanded);
}

my $last_dir = "";
my $workbook;
my $sheet_num;
for my $file (@files) {
print "<$file>\n";
    open(FOO, "$file") || die "can't open $file";
    print "reading file $file\n";
    my @dirs = split(m|[\/\\]|, $file);
    my $dir = $dirs[$#dirs - 1] || "currentdir";
    if ($last_dir ne $dir) {
	print "creating file $dir.xls\n";
	# Add a worksheet
	$workbook = Spreadsheet::WriteExcel::Big->new("$dir.xls");
	$last_dir = $dir;
	$sheet_num = 1;
    }

    $file =~ s/^.*[\/\\]//;		# remove /
    $file =~ s/\.[^.]*$//;	# remove .

    # $file = substr($file, 0, 31);
    # my $worksheet = $workbook->add_worksheet($file);
    my $worksheet = $workbook->add_worksheet($sheet_num++);
    my $row = 0;
    while (<FOO>) {
	s/[\r\n]+$//;
	my @cols = split /\t/;
	for (my $col = 0; $col <= $#cols; $col++) {
	    $cols[$col] =~ s/^"//;
	    $cols[$col] =~ s/"$//;
	    $worksheet->write($row, $col, $cols[$col]);
	}
	$row++;
    }
}

# $workbook->close();
