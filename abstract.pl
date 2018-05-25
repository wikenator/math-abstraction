#!/usr/bin/perl

use lib('/home/arnold/git_repos/detexify');
use lib('/home/arnold/git_repos/math-abstraction');

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use Abstraction qw(abstract update_abstraction);

my $debug = 0;
my $test = 0;

GetOptions(
	'debug|d' => \$debug,
	'test|t' => \$test
) or die "Usage: $0 [--debug | -d] [--test | -t]\n";

my $latexExpr = <STDIN>;
chomp($latexExpr);

my $detexExpr = '';
my $abstraction = '';

if ($test) {
	$abstraction = &update_abstraction('MATH', ['LITERAL'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['EXPRESSION'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['ROOT'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['LITERAL', 'EXPRESSION'], $debug);
	print "$abstraction\n";

} else {
	($detexExpr, $abstraction) = &abstract($latexExpr, $debug);
}

print "$detexExpr,$abstraction";
exit();
