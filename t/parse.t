# $Id$
use Test::More tests => 38;

use Mac::PropertyList;

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
</array>
</plist>
HERE

my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
</dict>
</plist>
HERE

my $string1_0 =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>This is it</string>
</plist>
HERE

my $string0_9 =<<"HERE";
<?xml version="0.9" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>This is it</string>
</plist>
HERE

my $nested_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Roscoe</key>
		<integer>1</integer>
		<key>Boolean</key>
		<true/>
	</dict>
</dict>
</plist>
HERE

eval {
	my $plist = Mac::PropertyList::parse_plist( $array );

	isa_ok( $plist, 'HASH' );
	ok( exists $plist->{type} );
	ok( $plist->{type} eq 'array' );
	ok( exists $plist->{value} );
	isa_ok( $plist->{value}, 'ARRAY' );
	
	my $elements = $plist->{value};
	isa_ok( $elements->[0], 'HASH' );
	isa_ok( $elements->[1], 'HASH' );

	ok( $elements->[0]{value} eq 'Mimi' );
	ok( $elements->[1]{value} eq 'Roscoe' );
	};

eval {
	my $plist = Mac::PropertyList::parse_plist( $dict );

	isa_ok( $plist, 'HASH' );
	ok( exists $plist->{type} );
	ok( $plist->{type} eq 'dict' );
	ok( exists $plist->{value} );
	isa_ok( $plist->{value}, 'HASH' );
	
	my $hash = $plist->{value};

	ok( exists $hash->{Mimi} );
	isa_ok( $hash->{Mimi}, 'HASH' );
	ok( exists $hash->{Mimi}{value} );
	ok( $hash->{Mimi}{value} eq 'Roscoe' );
	};

foreach my $string ( ( $string0_9, $string1_0 ) )
	{
	eval {
		my $plist = Mac::PropertyList::parse_plist( $string );
	
		isa_ok( $plist, 'HASH' );
		ok( exists $plist->{type} );
		ok( $plist->{type} eq 'string' );
		ok( $plist->{value}, 'This is it' );
		};
	}
	
eval {
	my $plist = Mac::PropertyList::parse_plist( $nested_dict );

	isa_ok( $plist, 'HASH' );
	ok( exists $plist->{type} );
	ok( $plist->{type} eq 'dict' );
	ok( exists $plist->{value} );
	isa_ok( $plist->{value}, 'HASH' );
		
	my $hash = $plist->{value}{Mimi};

	isa_ok( $hash, 'HASH' );
	ok( exists $hash->{type} );
	ok( $hash->{type} eq 'dict' );
	ok( exists $hash->{value} );
	isa_ok( $hash->{value}, 'HASH' );

	ok( $hash->{value}{Roscoe}{value} eq "1");
	ok( $hash->{value}{Boolean}{value} eq 'true' );
	};
