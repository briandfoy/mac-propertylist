#!/usr/bin/env perl

use strict qw(subs vars);
use warnings;

use Test::More;

use File::Spec::Functions;

my $class = 'Mac::PropertyList';
my @methods = qw( as_perl );

use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $type_class = $class . '::array';
my $parse_fqname = $class . '::parse_plist_file';

my $test_file = catfile( qw( plists the_perl_review.abcdp ) );
ok( -e $test_file, "Test file for binary plist is there" );

{
my $plist = &{$parse_fqname}( $test_file );
isa_ok( $plist, "${class}::dict" );
can_ok( $plist, @methods );

my $perl = $plist->as_perl;
is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Organization returns the right value'
	);

is(
	$perl->{ 'Organization' },
	'The Perl Review',
	'Shallow access returns the right value'
	);

is(
	$perl->{'Address'}{'values'}[0]{'City'},
	'Chicago',
	'Deep access returns the right value'
	);
}

done_testing();
