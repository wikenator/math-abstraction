#!/usr/bin/perl

use lib('../detexify');
use lib('../math-abstraction');

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Abstraction qw(abstract update_abstraction);

my $debug = 0;
my $test = 0;

GetOptions(
	'debug|d' => \$debug,
	'test|t' => \$test
) or die "Usage: $0 [--debug | -d] [--test | -t]\n";

my $detexExpr = '';
my $abstraction = '';
my $latexExpr = <STDIN>;
chomp($latexExpr);

if ($test) {
	$abstraction = &update_abstraction('MATH', ['LITERAL'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['EXPRESSION'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['SYMBOLIC'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['VARIABLE'], $debug);
	print "$abstraction\n";
	$abstraction = &update_abstraction($abstraction, ['LITERAL', 'FRACTION'], $debug);
	print "$abstraction\n";

} else {
	($detexExpr, $abstraction) = &abstract($latexExpr, $debug);
}

print "detexed: $detexExpr\nabstraction: $abstraction\n";
exit();
