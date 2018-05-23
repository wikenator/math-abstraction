package Abstraction;

# Author: Arnold Wikey
# Creation Date: May 2018
# Description: Abstract math objects into string representations.

use lib('../detexify');

use strict;
use warnings;
use Detex qw(detex);
use Exporter;
use Data::Dumper;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(abstract compare_inner_abstraction compare_inner_outer_abstraction update_abstraction);
%EXPORT_TAGS = (
	DEFAULT => [qw(abstract compare_inner_abstraction compare_inner_outer_abstraction update_abstraction)],
	All	=> [qw(abstract compare_inner_abstraction compare_inner_outer_abstraction update_abstraction)]
);

our $debug;
our $abstract_tree = {
	MATH => {
		LITERAL => [
			'COORDINATE',
			'INTERVAL',
			'ORDEREDSET',
			'SEQUENCE',
			'TIME',
			{ NUMBER => [
				{ DECIMAL => [
					'PERCENT'
				]},
				'ANGLE',
				'DEGREE',
				'FACTORIAL',
				'PERCENT'
			]},
			{ FRACTION => [
				{ MIXED => [
					'PERCENT'
				]},
				'PERCENT'
			]},
			{ EXPRESSION => [
				'ABSOLUTEVALUE',
				'EXPONENTIAL',
				'LOGARITHM',
				'POWER',
				'ROOT'
			]}
		],
		SYMBOLIC => {
			VARIABLE => [
				'ANGLE',
				'DEGREE',
				'CONSTANT',
				'COORDINATE',
				'INFINITY',
				'ORDEREDSET'
			],
			INEQUALITY => [
				'ANGLE',
				'TRIGONOMETRY',
				'SUMMATION'
			],
			EQUALITY => [
				'ANGLE',
				'COORDINATE',
				'EXPLICIT',
				'FUNCTION',
				'IMPLICIT',
				'MODULAR',
				'SUMMATION',
				'SYSTEM',
				'TRIGONOMETRY',
				{ GEOMETRY => [
					'ANGLE'
				]}
			],
			EXPRESSION => [
				'ABSOLUTEVALUE',
				'EXPONENTIAL',
				'FACTORIAL',
				{ 'DECIMAL' => [
					'PERCENT'
				]},
				{ FRACTION => [
					{ 'MIXED' => [
						'PERCENT'
					]},
					'PERCENT'
				]},
				'LOGARITHM',
				'ROOT',
				{ CALCULUS => [
					'DIFFERENTIALEQN',
					{ MULTIVAR => [
						'DIFFERENTIAL',
						'INTEGRAL',
						'LIMIT',
						'VECTOR'
					]},
					{ SINGLEVAR => [
						'DIFFERENTIAL',
						'INTEGRAL',
						'LIMIT'
					]}
				]},
				{ GEOMETRY => [
					'ANGLE',
					'TRIANGLE'
				]},
				{ LINEARALG => [
					'MATRIX',
					'VECTOR'
				]}
			]
		}
	}
};

sub abstract {
	my $latexExpr = shift;
	our $debug = shift;
	my $detexExpr;
	my $abstraction;

	($detexExpr, $abstraction) = &detex($latexExpr, 'f', $debug, 1);

	return $detexExpr, $abstraction;
}

sub compare_inner_abstraction {
	my $new_abstract = shift;
	my $old_abstract = shift;

	if ($new_abstract eq '') {
		return $old_abstract;

	} elsif ($new_abstract eq 'SYMBOLIC' and 
	$old_abstract eq 'LITERAL') {
		return $new_abstract;

#	} elsif ($new_abstract eq 'EXPRESSION' and
#	not grep(split(/:/, $old_abstract)[0], keys %{$abstract_tree->{MATH}->{SYMBOLIC}})) {
#		return $new_abstract;
	}

	return $old_abstract;
}

sub compare_inner_outer_abstraction {
	my $new_inner_abstract = shift;
	my $old_inner_abstract = shift;
	my $new_outer_abstract = shift;
	my $old_outer_abstract = shift;
	$new_inner_abstract = '' if not defined $new_inner_abstract;
	$old_inner_abstract = '' if not defined $old_inner_abstract;
	$new_outer_abstract = '' if not defined $new_outer_abstract;
	$old_outer_abstract = '' if not defined $old_outer_abstract;
	my ($ia, $oa);

	if ($new_inner_abstract eq '') { $ia = $old_inner_abstract; }
	if ($new_outer_abstract eq '') { $oa = $old_outer_abstract; }
	if ($old_inner_abstract eq '') { $ia = $new_inner_abstract; }
	if ($old_outer_abstract eq '') { $oa = $new_outer_abstract; }

	my $ooa_first = (split(':', $old_outer_abstract))[0];
	my $ooa_size = scalar (split(':', $old_outer_abstract));
	my $noa_first = (split(':', $new_outer_abstract))[0];
	my $noa_size = scalar (split(':', $new_outer_abstract));

	if ($old_outer_abstract ne '') {
		$ia = $new_inner_abstract;

		if ($new_inner_abstract eq 'SYMBOLIC') {
			$oa = 'EXPRESSION';

		} elsif ($ooa_size != $noa_size and
		$ooa_first eq $noa_first and
		grep($ooa_first, keys %{$abstract_tree->{MATH}->{SYMBOLIC}})) {
			$oa = $ooa_first;

		} elsif ($new_inner_abstract eq 'LITERAL') {
			if ($ooa_size != $noa_size and
			$ooa_first eq $noa_first and
			grep($ooa_first, keys %{$abstract_tree->{MATH}->{SYMBOLIC}})) {
				$oa = $ooa_first;

			} else {
				$oa = $old_outer_abstract;
			}
		}

	} elsif ($new_inner_abstract eq 'SYMBOLIC' and
	not grep($ooa_first, keys %{$abstract_tree->{MATH}->{SYMBOLIC}})) {
		$oa = "EXPRESSION:$old_outer_abstract";
	}

	return $ia, $oa;
}

sub update_abstraction {
	my $abstraction = shift;
	my $next_class = shift;
	$debug = shift;
	$debug = 0 if not defined $debug;
	our $abstract_tree;
	my $idx = $abstract_tree;
	my @atree = split(':', $abstraction);

	if ($debug) {
		print STDERR Dumper($next_class);
		print STDERR "abstraction: $abstraction\n";
	}

	# return current abstraction if next_class is empty
	if (not @{$next_class}) { return $abstraction; }

	# traverse abstraction tree up until the current abstract node
	for my $i (0 .. $#atree) {
		if ($debug) { print STDERR "atree: $atree[$i]\n"; }

		if ((ref $idx) eq 'ARRAY') {
			my $found = 0;

			foreach my $item (@{$idx}) {
				if ((ref $item) eq 'HASH') {
					foreach (keys %{$item}) {
						if ($_ eq $atree[$i]) {
							$idx = $item->{$_};
							$found = 1;

						} elsif ($_ eq @$next_class[0]) {
							$idx = $item->{$_};
							$found = 1;
							last;
						}
					}

				} elsif ((ref \$item) eq 'SCALAR' and 
				$item eq $atree[$i]) {
					$idx = $item;
					$found = 1;
					last;
				}
			}

			if (not $found) {
				$abstraction = &update_abstraction("NOPARSE", [], $debug);

				return $abstraction;
			}

			if ($debug) { print STDERR "arr tree: $atree[$i]\n"; }

		} else {
			if (exists $idx->{@$next_class[0]}) {
				$idx = $idx->{@$next_class[0]};

				return &update_abstraction(join(':', @atree[0 .. $i-1]) . ":@$next_class[0]", [@$next_class[1 .. $#{$next_class}]], $debug);

			} else {
				$idx = $idx->{$atree[$i]};
			}

			if ($debug) { print STDERR "current tree: $atree[$i]\n"; }
		}
	}

	# append next abstraction classes to abstraction string
	foreach my $leaf (@{$next_class}) {
		if ($debug) { print STDERR "atree: $atree[0]\tleaf: $leaf\n"; }

		if ((ref $idx) eq 'ARRAY') {
			my $found = 0;

			if ($debug) { print "leaf array: " . Dumper($idx) . "\n"; }

			foreach my $item (@{$idx}) {
				if ((ref $item) eq 'HASH') {
					foreach (keys %{$item}) {
						if ($_ eq $leaf) {
							$idx = $item->{$_};
							$found = 1;
							last;
						}
					}

				} elsif ((ref \$item) eq 'SCALAR' and 
				$item eq $leaf) {
					$idx = $leaf;
					$found = 1;
					last;
				}
			}

			if (not $found) {
				$abstraction = &update_abstraction("NOPARSE", [], $debug);

				return $abstraction;
			}

			$abstraction = &update_abstraction("$abstraction:$leaf", [@$next_class[1 .. $#{$next_class}]], $debug);

		} else {
			my $found = 0;

			foreach (keys %{$idx}) {
				if ($_ eq $leaf) {
					$idx = $idx->{$leaf};
					$found = 1;
					last;
				}
			}

			if (not $found) {
				$abstraction = &update_abstraction("NOPARSE", [], $debug);

				return $abstraction;
			}

			$abstraction = &update_abstraction("$abstraction:$leaf", [@$next_class[1 .. $#{$next_class}]], $debug);
		}

		return $abstraction;
	}
}

1;
