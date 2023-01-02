#!perl
use strict;
use warnings;

use v5.10;
use experimental qw(signatures);

use Math::BigInt;

#  340,282,366,920,938,463,463,374,607,431,768,211,455
#  340282366920938463463374607431768211455
# −170,141,183,460,469,231,731,687,303,715,884,105,728
# my $n = Math::BigInt->from_base_num([(0xFF)x16], 256);

#say "340,282,366,920,938,463,463,374,607,431,768,211,455" =~ s/,//gr;
#say $n;
#say $n->to_bytes;

my $n = Math::BigInt->new("340282366920938463463374607431768211455");
$n = 0x7F_FF_FF_FF_FF;

my $bytes = to_bytes( $n, size($n) );

say "AT END: ", join ":", map { sprintf '%02x', ord } split //, $bytes;

sub size ($value) {
	state $base = 256;

	my $abs  =  eval { $value->isa( 'Math::BigInt' ) } ? $value->copy->babs : abs($value);

	my $exp8 =  eval { $abs->isa( 'Math::BigInt' ) } ?
		$abs->blog($base) : log($abs)/log($base);

	my $byte_size = ceil8($exp8);
    }

sub ceil8 ($n) {
	state $powers = [ qw( 1 2 4 8 16 ) ];

	foreach my $power ( @$powers ) {
		return $power if $n < $power;
		}

	return;
	}

sub to_bytes ( $value, $byte_size ) {
	state $formats = {
		 1  => 'C',
		 2  => 'S',
		 4  => 'N',
		 8  => 'Q>',
		 16 => 'X',
		};

	my $bytes = eval { $value->isa( 'Math::BigInt' ) } ? do { say "to_bytes BigInt"; $value->to_bytes } : pack( $formats->{$byte_size}, $value );

	my $padding = "\000" x ($byte_size - length($bytes));
	$bytes = $padding . $bytes;
	}
