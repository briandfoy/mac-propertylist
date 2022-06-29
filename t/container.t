#!/usr/bin/env perl

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

foreach my $type ( qw(dict array) ) {
	my $type_class = $class . '::'. $type;
	my $dict = $type_class->new;
	isa_ok( $dict, $type_class );
	}

done_testing();
