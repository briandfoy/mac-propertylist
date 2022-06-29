#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';

my $Class = 'Mac::PropertyList';
use_ok( $Class );

$Class->import( 'parse_plist_fh' );

my $File = "plists/com.apple.systempreferences.plist";

ok( -e $File, "Sample plist file exists" );

########################################################################
{
ok(
	open( my( $fh ), $File ),
	"Opened $File"
	);

my $plist = parse_plist_fh( $fh );

ok( $plist, "return value is not false" );
isa_ok( $plist, "${Class}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}

########################################################################

{
ok(
	open( FILE, $File ),
	"Opened $File"
	);

my $plist = parse_plist_fh( \*FILE );

ok( $plist, "return value is not false" );
isa_ok( $plist,"${Class}::dict" );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
test_plist( $plist );
}



########################################################################

sub test_plist
	{
	my $plist = shift;

	my $value = eval { $plist->value->{NSColorPanelMode}->value };
	print STDERR $@ if $@;
	is( $value, 5, "NSColorPanelMode has the right value" );
	}
