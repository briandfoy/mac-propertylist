#!/usr/bin/env perl

use Test::More;

use Mac::PropertyList;

########################################################################
# Test the dict bits
my $dict = Mac::PropertyList::dict->new();
isa_ok( $dict, "Mac::PropertyList::dict" );

########################################################################
# Test the array bits
my $array = Mac::PropertyList::array->new();
isa_ok( $array, "Mac::PropertyList::array" );

done_testing();
