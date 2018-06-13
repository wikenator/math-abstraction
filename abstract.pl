#!/usr/bin/perl

use lib('/home/arnold/git_repos/detexify');
use lib('/home/arnold/git_repos/math-abstraction');

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use Detex qw(abstract);
use Abstraction qw(update_abstraction);

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
	if ($latexExpr =~ /(<=|>=|\\le[^f]|\\ge|\\doteq|<|>|=)/ and
	$latexExpr !~ /_\{[^\{\}]*?=[^\{\}]*?\}/ and
	$latexExpr !~ /\^\{[^\{\}]*?=[^\{\}]*?\}/) {
		if ($debug) { print STDERR "equality found\n"; }

		my @args_split = ($latexExpr =~ /(<=|>=|\\le[^f]|\\ge|\\doteq|<|>|=)/);
		my @args = split(/<=|>=|\\le[^f]|\\ge|\\doteq|<|>|=/, $latexExpr);
		my $eq_ineq = (($args_split[0] eq '=' or $args_split[0] eq '\doteq') ? 'EQUALITY' : 'INEQUALITY');
		my @abstract_tree;

		if (scalar @args > 2) {
			$abstraction = "MATH:SYMBOLIC:$eq_ineq:COMPOUND";

		} else {
			foreach my $i (0 .. $#args) {
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
						$abstraction = "MATH:LITERAL:EXPRESSION:$eq_ineq";

					# =a
					} else {
						$abstraction = "MATH:SYMBOLIC:$eq_ineq";
					}

				} elsif (not defined $args[$i]) {
					# LITERAL=
					if ($abstraction =~ /^LITERAL/) {
						$abstraction = "MATH:LITERAL:EXPRESSION:$eq_ineq";

					# a=
					} else {
						$abstraction = "MATH:SYMBOLIC:$eq_ineq";
					}

				} elsif ($abstraction =~ /^LITERAL/) {
					# LITERAL=a
					if ($abstract_tree[1] and
					$abstract_tree[1] eq 'LITERAL' and
					(not defined $abstract_tree[2] or
					($abstract_tree[2] and
					$abstract_tree[2] ne 'EXPRESSION'))) {
						$abstraction = "MATH:LITERAL:EXPRESSION:$eq_ineq";

					# a=b
					} else {
						$abstraction = "MATH:SYMBOLIC:$eq_ineq";
					}

				} elsif ($abstraction eq 'MATH:SYMBOLIC:CONSTANT' or
				$abstraction eq 'MATH:SYMBOLIC:ANGLE' or
				$temp_abstract eq 'MATH:SYMBOLIC:CONSTANT' or
				$temp_abstract eq 'MATH:SYMBOLIC:ANGLE') {
					$abstraction = "MATH:SYMBOLIC:$eq_ineq:EXPLICIT";

				} elsif ($abstraction eq 'MATH:SYMBOLIC:EXPRESSION:FUNCTION' or
				$abstraction eq 'MATH:SYMBOLIC:LINEARALG:VECTOR' or
				$abstraction eq 'MATH:SYMBOLIC:CALCULUS:SINGLEVAR:VECTOR' or
				$abstraction eq 'MATH:SYMBOLIC:CALCULUS:MULTIVAR:VECTOR') {
					my @a = split(':', $abstraction);
					$abstraction = "$a[0]:$a[1]:$eq_ineq:" . join(':', @a[2 .. $#a]);

				} else {
					$abstraction = "MATH:SYMBOLIC:$eq_ineq:IMPLICIT";
				}
			}
		}

		if (scalar @args == 2) {
			$detexExpr = join($args_split[0], @args);

		} else {
			$detexExpr = $args[0] . $args_split[0];
		}

	} else {
		if ($debug) { print STDERR "no equality found\n"; }

		($detexExpr, $abstraction) = &abstract($latexExpr, $debug);
	}
}

print "$detexExpr#@#$abstraction";
exit();
