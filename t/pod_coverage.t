#!/usr/bin/env perl

use Test::More;
eval "use Test::Pod::Coverage";

if( $@ ) {
	plan skip_all => "Test::Pod::Coverage required for testing POD";
	}
else {
	plan tests => 1;

	pod_coverage_ok( "Mac::PropertyList", {
		trustme => [ qr/^read_/, qr/indent/ ],
		},
		);
	}
