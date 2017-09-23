
package xml_parser;

use XML::Parser;
use XML::Parser::EasyTree;

our $debug = 0;	# use $xml_parser::debug to change

# $XML::Parser::EasyTree::Noempty = 1;

sub ::parse_xml_file {
    my ($file, $start_func, $end_func) = @_;
    my $p1 = new XML::Parser(Style => 'EasyTree');
    my $tree = $p1->parsefile($file);
    traverse_tree($tree, $start_func, $end_func);
}


sub traverse_tree {
    my ($tree, $start_func, $end_func) = @_;
    my @branches = @$tree;
    printf STDERR "got %d brances from root\n", scalar(@branches) if $debug;
    return if ! @branches;
    for my $branch (@branches) {
	traverse_node($branch, $start_func, $end_func);
    }
}

sub traverse_node {
    my ($node, $start_func, $end_func) = @_;
    &$start_func($node) if defined $start_func;
    my $type = $node->{'type'};
    my $name = $node->{'name'};
    my $content = $node->{'content'};
    my $attrib = $node->{'attrib'};
    my @attrib = %$attrib;
    if ($type eq 'e') {
	warn "traversing node $name type $type attrib [@attrib]\n" if $debug;
	my @content = @$content;
	for my $child (@content) {
	    traverse_node($child, $start_func, $end_func);
	}
    }
    &$end_func($node) if defined $end_func;
}

1;
