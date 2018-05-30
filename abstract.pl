#!/usr/bin/perl

use lib('/home/arnold/git_repos/detexify');
use lib('/home/arnold/git_repos/math-abstraction');

use strict;
use warnings;
use Data::Dumper;
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
my $coord = 0;
my $temp_abstract;

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
	if ($latexExpr =~ /=/) {
		my @args = split('=', $latexExpr);

		foreach my $i (0 .. $#args) {
			if (not $args[$i]) {
				$abstraction = 'NOPARSE';
				next;
			}

			($args[$i], $temp_abstract) = &abstract($args[$i], $debug);

			if ($abstraction eq '') {
				$abstraction = $temp_abstract;

			} elsif ($abstraction eq 'NOPARSE') {
				my @abstract_tree = split(':', $temp_abstract);

				if ($abstract_tree[1] and
				$abstract_tree[1] eq 'LITERAL' and
				(not $abstract_tree[2] or
				($abstract_tree[2] and
				$abstract_tree[2] ne 'EXPRESSION'))) {
					$abstraction = 'LITERAL:EXPRESSION:EQUALITY';

				} else {
					$abstraction = 'SYMBOLIC:EQUALITY';
				}
			}
		}

		if ($#args > 2) { $abstraction = 'SYMBOLIC:EQUALITY:COMPOUND'; }

		$detexExpr = join('=', @args);

	} else {
		($detexExpr, $abstraction) = &abstract($latexExpr, $debug);
	}
}

print "$detexExpr,$abstraction";
exit();
