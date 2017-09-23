
use LWP::Simple;
use HTML::FormatText;
use HTML::Parse;
use IO::Handle;

package ncbi;

my $formatter = HTML::FormatText->new();
my $base = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils';

sub ::get_gene_ids {
    my ($term) = @_;
    return () if $term eq '';
    my $url = sprintf "$base/esearch.fcgi?db=gene&term=%s[ACCN]", $term;
    my $line = GET($url);
    my @ids;
    while ($line =~ m|<Id>(.*)</Id>|g) {
	push(@ids, $1);
    }
    return @ids;
}

my %summary_hash;

sub ::get_summary {
    my ($sym) = @_;
    return undef if $sym eq '';
    my ($id, $desc) = ::get_id($sym);
    return '' if $id eq '';
    my $res = $summary_hash{$id};
    return $res if defined $res;
    my $line = GET("$base/esummary.fcgi?db=protein&id=$id");
    my $html = HTML::Parse::parse_html($line);
    $res = $formatter->format($html);
    return $res;
}

sub ::get_gene_info {
    my $line = GET("$base/esummary.fcgi?db=gene&id=$_[0]");
    my @info;
    $line =~ m|<Item Name="Orgname" Type="String">(.*)</Item>|;
    push(@info, $1);
    $line =~ m|<Item Name="Name" Type="String">(.*)</Item>|;
    push(@info, $1);
    $line =~ m|<Item Name="OtherAliases" Type="String">(.*)</Item>|;
    push(@info, $1);
    $line =~ m|<Item Name="Description" Type="String">(.*)</Item>|;
    push(@info, $1);
    return @info;
}

sub ::get_id {
    my $line = GET("http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=protein&term=$_[0]");
    my $id = $1 if $line =~ m|<Id>(.*)</Id>|;
    my $desc = $1 if $line =~ m|<OutputMessage>(.*)</OutputMessage>|;
    return ($id, $desc);
}

sub ::get_pair {
    my ($term) = @_;
    my $sum = ::get_summary($term);
    if ($sum =~ /gi\|(.*?)\|\w+\|(.*?)\|/) {
	return ($2, $1);
    }
    else {
	return undef;
    }
}

sub ::get_latest_ids {
    my ($id) = @_;
    return undef if $id eq '';
    my $res = ::get_summary($id);
    while ($res =~ /replaced (\S+)/) {
	my $by = $1;
	$res = ::get_summary($by);
	$comment = 'replaced';
    }
    if ($res =~ /suppressed|removed|dead|discontinued/) {
	return ("removed", "removed");
    }
    elsif ($res =~ /gi\|(.*?)\|\w+\|(.*?)\|/) {
	return ($2, $1);
    }
    return undef;
}

sub GET {
    my ($url) = @_;
    my $line = ::get($url);
    my $count = 0;
    while (! defined $line && $count < 5) {
	warn "query failed, trying again...\n";
	$line = ::get($url);
    }
    exit 1 if ! defined $line;
    return $line;
}

1;
