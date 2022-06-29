#!/usr/bin/env perl

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $parse_fqname = $class . '::parse_plist';

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi &amp; Buster</string>
	<string>Buster &quot;Bean&quot;</string>
</array>
</plist>
HERE

use Data::Dumper;

my $plist  = &{$parse_fqname}( $array );
diag( Dumper( $plist ) . "\n" ) if $ENV{DEBUG};

is( $plist->[0]->value, 'Mimi & Buster' );
is( $plist->[1]->value, 'Buster "Bean"' );

done_testing();
