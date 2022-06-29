#!/usr/bin/env perl

use Test::More;

my @classes = qw(
	Mac::PropertyList
	Mac::PropertyList::ReadBinary
	Mac::PropertyList::WriteBinary
	);

foreach my $class ( @classes ) {
	BAIL_OUT( "$class did not compile\n" ) unless use_ok( $class );
	}

done_testing();
