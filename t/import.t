#!/usr/bin/env perl

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = Mac::PropertyList->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );


foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}

Mac::PropertyList->import( ":all" );

foreach my $name ( @Mac::PropertyList::EXPORT_OK )
	{
	ok( defined( &$name ), "$name is now defined yet" );
	}

done_testing();
