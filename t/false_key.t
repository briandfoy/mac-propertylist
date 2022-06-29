#!/usr/bin/env perl

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $parse_fqname = $class . '::parse_plist';

my $good_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>0</key>
	<string>Roscoe</string>
	<key> </key>
	<string>Buster</string>
</dict>
</plist>
HERE

my $bad_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key></key>
	<string>Roscoe</string>
</dict>
</plist>
HERE

my $ok = eval {
	my $plist = &{$parse_fqname}( $good_dict );
	};
ok( $ok, "Zero and space are valid key values" );

TODO: {
    local $TODO = "Doesn't work, but poor Andy doesn't know why.";

    my $ok = eval {
		my $plist = &{$parse_fqname}( $good_dict );
		};

	like( $@, qr/key not defined/, "Empty key causes $parse_fqname to die" );
	}

done_testing();
