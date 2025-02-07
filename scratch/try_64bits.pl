#!perl
use strict;
use warnings;

use v5.10;
use experimental qw(signatures);
use Mojo::Util qw(dumper);

use Math::BigInt;
use Mac::PropertyList qw( plist_as_string );
my $n = Math::BigInt->new('0xFF_FF_FF_FF_FF_FF_FF_FF');


my %hash = (
	string => Mac::PropertyList::string->new('foo'),
	bignum => Mac::PropertyList::integer->new($n),
	);

my $pl = Mac::PropertyList::dict->new( \%hash );
#say dumper($pl);

say plist_as_string( $pl );
