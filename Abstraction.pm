package Abstraction;

# Author: Arnold Wikey
# Creation Date: May 2018
# Description: Abstract math objects into string representations.

use lib('/home/arnold/git_repos/detexify');

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(compare_inner_abstraction compare_outer_abstraction compare_inner_outer_abstraction update_abstraction);
%EXPORT_TAGS = (
	DEFAULT => [qw(compare_inner_abstraction compare_outer_abstraction compare_inner_outer_abstraction update_abstraction)],
	All	=> [qw(compare_inner_abstraction compare_inner_outer_abstraction update_abstraction)]
);

our $debug;
our $abstract_tree = {
	MATH => {
		LITERAL => [
			'FACTORIAL',
			'INTERVAL',
			'ORDEREDSET',
			'PERCENT',
			'RATIO',
			'SEQUENCE',
			'SET',
			'TIME',
			{ DECIMAL => [
				'PERCENT'
			]},
			{ DEGREE => [
				'DMS'
			]},
			{ FRACTION => [
				{ MIXED => [
					'PERCENT'
				]},
				'PERCENT'
			]},
			{ EXPRESSION => [
				'ABSOLUTEVALUE',
				'CEILING',
				'COMPLEX',
				'EQUALITY',
				'EXPONENTIAL',
				'FLOOR',
				'LOGARITHM',
				'MODULAR',
				'ROOT',
				'TRIGONOMETRY'
			]}
		],
		SYMBOLIC => [
			'ANGLE',
			'DEGREE',
			'CONSTANT',
			'FACTORIAL',
			'INFINITY',
			'INTERVAL',
			'ORDEREDSET',
			'PRODUCT',
			'RATIO',
			'SET',
			'SUMMATION',
			{ SEQUENCE => [
				'COORDINATE'
			]},
			{ INEQUALITY => [
				'COMPOUND',
				'EXPLICIT',
				'IMPLICIT',
				'SUMMATION'
			]},
			{ SYSTEM => [
				'EQUALITY',
				'INEQUALITY',
				'IVP',
				'MODULAR',
				'TABLEDATA'
			]},
			{ EQUALITY => [
				'COMPOUND',
				{ EXPLICIT => [
					'FUNCTION',
					'ORDEREDSET',
					'SYSTEM'
				]},
				'IMPLICIT',
				'MODULAR',
				{ GEOMETRY => [
					'ANGLE'
				]},
				{ LINEARALG => [
					'MATRIX',
					'VECTOR'
				]},
				{ CALCULUS => {
					SINGLEVAR => [
						'VECTOR'
					]}
				}
			]},
			{ EXPRESSION => [
				'ABSOLUTEVALUE',
				'CEILING',
				'COMPLEX',
				'EXPONENTIAL',
				'FLOOR',
				'FUNCTION',
				'LOGARITHM',
				'MODULAR',
				'ROOT',
				'TRIGONOMETRY'
			]},
			{ DECIMAL => [
				'PERCENT'
			]},
			{ FRACTION => [
				{ 'MIXED' => [
					'PERCENT'
				]},
				'PERCENT'
			]},
			{ CALCULUS => {
				MULTIVAR => [
					'INTEGRAL',
					'LIMIT',
					'VECTOR',
					{ DIFFERENTIAL => [
						'ODE',
						'PDE'
					]}
				],
				SINGLEVAR => [
					'INTEGRAL',
					'LIMIT',
					'VECTOR',
					{ DIFFERENTIAL => [
						'ODE'
					]}
				]
			}},
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
};

sub compare_inner_abstraction {
	my $new_abstract = shift;
	my $old_abstract = shift;
	my $debug = shift;

	if ($debug) { print STDERR "COMPIA old inner: $old_abstract, new inner: $new_abstract\n"; }

	if ($new_abstract eq '') {
		return $old_abstract;

	} elsif ($old_abstract eq '') {
		return $new_abstract;

	} elsif ($new_abstract eq 'SYMBOLIC' and 
	$old_abstract eq 'LITERAL') {
		return $new_abstract;

#	} elsif ($new_abstract eq 'EXPRESSION' and
#	not grep(split(/:/, $old_abstract)[0], keys %{$abstract_tree->{MATH}->{SYMBOLIC}})) {
#		return $new_abstract;
	}

	return $old_abstract;
}

sub compare_outer_abstraction {
	my $new_abstract = shift;
	my $old_abstract = shift;
	my $debug = shift;

	if ($debug) { print STDERR "COMPOA old outer: $old_abstract, new outer: $new_abstract\n"; }

	my $oa_first = ($old_abstract ne '') ? (split(':', $old_abstract))[0] : '';
	my $na_first = (split(':', $new_abstract))[0];

	if ($new_abstract eq '') {
		return $old_abstract;

	} elsif ($old_abstract eq '') {
		return $new_abstract;

	} elsif ($old_abstract eq $new_abstract) {
		return $old_abstract;

	} elsif ($old_abstract eq 'ORDEREDSET' or
	$old_abstract eq 'SET' or
	$old_abstract eq 'EXPRESSION:COMPLEX' or
	$old_abstract eq 'EXPRESSION:MODULAR') {
		return $old_abstract;

	} elsif ($old_abstract eq 'PERCENT' and
	$new_abstract eq 'FRACTION') {
		return "$new_abstract:$old_abstract";
	}

	if ($oa_first ne '') {
		if ($debug) { print STDERR "COMPOA comparing firsts\n"; }

		if ($oa_first eq $na_first) {
			if ($oa_first eq 'EXPRESSION') {
				return $na_first;

			} elsif ($oa_first eq 'FRACTION') {
				if ((split(':', $new_abstract))[1]) {
					return "$old_abstract:" . (split(':', $new_abstract))[1];

				} else {
					return $old_abstract;
				}

			} elsif (scalar (split(':', $new_abstract)) > 1) {
				return $new_abstract;

			} else {
				return $old_abstract;
			}

		} elsif ($oa_first eq 'EXPRESSION') {
			if ($new_abstract eq 'ORDEREDSET') {
				return $new_abstract;

			} elsif ($new_abstract eq 'FRACTION') {
				return $old_abstract;
			}

		} elsif ($na_first eq 'EXPRESSION' and
		$old_abstract eq 'CONSTANT') {
			return $new_abstract;

		} elsif ($oa_first eq 'FRACTION' and
		$new_abstract eq 'CONSTANT') {
			return $old_abstract;

		# if new outer abstract is A and old outer abstract is B, new outer abstract should be EXPRESSION
		} else {
			return 'EXPRESSION';
		}
	}

	return $old_abstract;
}

sub compare_inner_outer_abstraction {
	my $new_inner_abstract = shift;
	my $old_inner_abstract = shift;
	my $new_outer_abstract = shift;
	my $old_outer_abstract = shift;
	my $debug = shift;
	$new_inner_abstract = '' if not defined $new_inner_abstract;
	$old_inner_abstract = '' if not defined $old_inner_abstract;
	$new_outer_abstract = '' if not defined $new_outer_abstract;
	$old_outer_abstract = '' if not defined $old_outer_abstract;
	my $ia = '';
	my $oa = '';

	if ($new_inner_abstract eq '') { $ia = $old_inner_abstract; }
	if ($new_outer_abstract eq '') { $oa = $old_outer_abstract; }
	# if old inner abstract is empty, old inner abstract should be new
	if ($old_inner_abstract eq '') { $ia = $new_inner_abstract; }
	# if old outer abstract is empty, old outer abstract should be new
	if ($old_outer_abstract eq '') { $oa = $new_outer_abstract; }

	my $ooa_first = ($old_outer_abstract ne '') ? (split(':', $old_outer_abstract))[0] : '';
	my $ooa_size = scalar (split(':', $old_outer_abstract));
	my $noa_first = (split(':', $new_outer_abstract))[0];
	my $noa_size = scalar (split(':', $new_outer_abstract));
	
	if ($debug) { print STDERR "COMPIAOA OIA: $old_inner_abstract, NIA: $new_inner_abstract\n\tOOA: $old_outer_abstract, NOA: $new_outer_abstract\n"; }

	## if new inner abstract is A:x and old inner abstract is A:y, new inner abstract should be A
	## if new inner abstract is A and old inner abstract is B, new inner abstract should be EXPRESSION

	# if old inner abstract is LITERAL and new inner abstract is SYMBOLIC, new inner abstract should be SYMBOLIC
	# if new inner abstract is SYMBOLIC, new outer abstract should be EXPRESSION
	if ($old_inner_abstract eq 'LITERAL' and
	$new_inner_abstract eq 'SYMBOLIC') {
		$ia = 'SYMBOLIC';
		$oa = 'EXPRESSION';
	}

	if ($old_inner_abstract eq $new_inner_abstract and
	$ia eq '') {
		$ia = $old_inner_abstract;
	}

	# if new outer abstract is A:x and old outer abstract is A:y, new outer abstract should be A
	if ($ooa_first ne '') {
		if ($debug) { print STDERR "COMPIAOA comparing inner outer firsts\n"; }

		if ($old_outer_abstract eq $new_outer_abstract) {
			$oa = $old_outer_abstract;

		} elsif ($noa_first and $ooa_first eq $noa_first) {
			$oa = $noa_first;

		# if new outer abstract is A and old outer abstract is B, new outer abstract should be EXPRESSION
		} elsif ($ia ne 'LITERAL') {
			if ($old_outer_abstract eq 'ORDEREDSET' or
			$old_outer_abstract eq 'SET') {
				$oa = $old_outer_abstract;

			} else {
				$oa = 'EXPRESSION';
			}
		}
	}

	if ($debug) { print STDERR "COMPIAOA selected abstractions: $ia, $oa\n"; }

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
		print STDERR "UPDATEABS abstraction: $abstraction\n";
	}

	# return current abstraction if next_class is empty
	if (not @{$next_class}) { return $abstraction; }

	# traverse abstraction tree up until the current abstract node
	for my $i (0 .. $#atree) {
		if ($debug) { print STDERR "UPDATEABS atree: $atree[$i]\n"; }

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

			if ($debug) { print STDERR "UPDATEABS arr tree: $atree[$i]\n"; }

		} else {
			if (exists $idx->{@$next_class[0]}) {
				$idx = $idx->{@$next_class[0]};

				return &update_abstraction(join(':', @atree[0 .. $i-1]) . ":@$next_class[0]", [@$next_class[1 .. $#{$next_class}]], $debug);

			} else {
				$idx = $idx->{$atree[$i]};
			}

			if ($debug) { print STDERR "UPDATEABS current tree: $atree[$i]\n"; }
		}
	}

	# append next abstraction classes to abstraction string
	foreach my $leaf (@{$next_class}) {
		if ($debug) { print STDERR "UPDATEABS atree: $atree[0]\tleaf: $leaf\n"; }

		if ((ref $idx) eq 'ARRAY') {
			my $found = 0;

			if ($debug) { print "UPDATEABS leaf array: " . Dumper($idx) . "\n"; }

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
