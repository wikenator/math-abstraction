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
		my @abstract_tree;

		if (scalar @args > 2) {
			$abstraction = 'MATH:SYMBOLIC:EQUALITY:COMPOUND';

		} else {
			foreach my $i (0 .. $#args) {
#				if (not $args[$i] and
#				$abstraction eq '') {
#					$abstraction = 'NOPARSE';
	#				next;
#				}

				($args[$i], $temp_abstract) = &abstract($args[$i], $debug);
				@abstract_tree = split(':', $temp_abstract);

				if ($abstraction eq '') {
					# =a
					if (not defined $args[$i]) {
						$abstraction = 'NOPARSE';

					# a=b
					} else {
						$abstraction = $temp_abstract;
					}

				} elsif ($abstraction eq 'NOPARSE') {
					# =LITERAL
					if ($abstract_tree[1] and
					$abstract_tree[1] eq 'LITERAL' and
					(not defined $abstract_tree[2] or
					($abstract_tree[2] and
					$abstract_tree[2] ne 'EXPRESSION'))) {
						$abstraction = 'MATH:LITERAL:EXPRESSION:EQUALITY';

					# =a
					} else {
						$abstraction = 'MATH:SYMBOLIC:EQUALITY';
					}

				} elsif (not defined $args[$i]) {
					# LITERAL=
					if ($abstraction =~ /^LITERAL/) {
						$abstraction = 'MATH:LITERAL:EXPRESSION:EQUALITY';

					# a=
					} else {
						$abstraction = 'MATH:SYMBOLIC:EQUALITY';
					}

				} elsif ($abstraction =~ /^LITERAL/) {
					# LITERAL=a
					if ($abstract_tree[1] and
					$abstract_tree[1] eq 'LITERAL' and
					(not defined $abstract_tree[2] or
					($abstract_tree[2] and
					$abstract_tree[2] ne 'EXPRESSION'))) {
						$abstraction = 'MATH:LITERAL:EXPRESSION:EQUALITY';

					# a=b
					} else {
						$abstraction = 'MATH:SYMBOLIC:EQUALITY';
					}

				} elsif ($abstraction eq 'MATH:SYMBOLIC:CONSTANT') {
					$abstraction = 'MATH:SYMBOLIC:EQUALITY:EXPLICIT';

				} elsif ($abstraction eq 'MATH:SYMBOLIC:EXPRESSION:FUNCTION') {
					$abstraction = 'MATH:SYMBOLIC:EQUALITY:EXPLICIT:FUNCTION';

				} else {
					$abstraction = 'MATH:SYMBOLIC:EQUALITY:IMPLICIT';
				}
			}
		}


		if (scalar @args == 2) {
			$detexExpr = join('=', @args);

		} else {
			$detexExpr = $args[0] . '=';
		}

	} else {
		($detexExpr, $abstraction) = &abstract($latexExpr, $debug);
	}
}

print "$detexExpr,$abstraction";
exit();
