#!/usr/bin/env perl

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

ok( ! defined( &parse_plist ), "parse_plist is not defined yet" );
my $result = $class->import( 'parse_plist' );
ok( defined( &parse_plist ), "parse_plist is now defined" );

my @subs = @{ $class . '::EXPORT_OK' };
foreach my $name ( @subs ) {
	next if $name eq 'parse_plist';
	ok( ! defined( &$name ), "$name is not defined yet" );
	}

Mac::PropertyList->import( ":all" );

foreach my $name ( @subs ) {
	ok( defined( &$name ), "$name is now defined yet" );
	}

done_testing();
