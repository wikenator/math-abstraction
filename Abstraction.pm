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
@EXPORT_OK = qw(abstract update_abstraction);
%EXPORT_TAGS = (
	DEFAULT => [qw(abstract update_abstraction)],
	All	=> [qw(abstract update_abstraction)]
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
				]}
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
				{ FRACTION => [
					'MIXED'
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

sub update_abstraction {
	my $abstraction = shift;
	my $next_class = shift;
	our $debug = shift;
	$debug = 0 if not defined $debug;
	our $abstract_tree;
	my $idx = $abstract_tree;#->{'MATH'};
	my $idx_cmp = $abstract_tree;
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

		if (ref $idx eq 'ARRAY') {
			my $found = 0;

			foreach my $item (@$idx) {
				if (ref $item eq 'HASH') {
					foreach (keys %$item) {
						if ($_ eq $atree[$i]) {
							$idx = $item->{$_};
							$found = 1;

						} elsif ($_ eq @$next_class[0]) {
							$idx = $item->{$_};
							last;
						}
					}

					if (not $found) {
						$abstraction = &update_abstraction("NOPARSE", [], $debug);

						return $abstraction;
					}

				} elsif (ref \$item eq 'SCALAR' && 
				$item eq $atree[$i]) {
					$idx = $item;
					last;
				}
			}

			if ($debug) { print STDERR "arr tree: $atree[$i]\n" . Dumper($idx) . "\n"; }

		} else {
			if (exists $idx->{@$next_class[0]}) {
				$idx = $idx->{@$next_class[0]};
				$abstraction = join(':', $atree[0 .. $i]);

				return &update_abstraction("$abstraction:@$next_class[0]", [@$next_class[1 .. $#{$next_class}]], $debug);

			} else {
				$idx = $idx->{$atree[$i]};
			}

			if ($debug) { print STDERR "current tree: $atree[$i]\n" . Dumper($idx) . "\n"; }
		}
	}

	# append next abstraction classes to abstraction string
	foreach my $leaf (@$next_class) {
		if ($debug) { print STDERR "atree: $atree[0]\tleaf: $leaf\n"; }

		if (ref $idx eq 'ARRAY') {
			my $found = 0;

			if ($debug) { print "leaf array: " . Dumper($idx) . "\n"; }

			foreach my $item (@$idx) {
				if (ref $item eq 'HASH') {
					foreach (keys %$item) {
						if ($_ eq $leaf) {
							$idx = $item->{$_};
							$found = 1;
							last;
						}
					}

				} elsif (ref \$item eq 'SCALAR' &&
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
			if (grep($leaf), $idx) {
				$idx = $idx->{$leaf};

			} else {
				$abstraction = &update_abstraction("NOPARSE", [], $debug);

				return $abstraction;
			}

			$abstraction = &update_abstraction("$abstraction:$leaf", [@$next_class[1 .. $#{$next_class}]], $debug);
		}

		return $abstraction;
	}
}

1;