# $Id$

use Test::More tests => 39;

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

my $plist = Mac::PropertyList::parse_plist( $array );

<<<<<<< parse.t
isa_ok( $plist, 'HASH' );
ok( exists $plist->{type} );
is( $plist->{type}, 'array' );
ok( exists $plist->{value} );
isa_ok( $plist->{value}, 'ARRAY' );

{	
my @elements = @{ $plist->{value} };
isa_ok( $elements[0], 'HASH'      );
isa_ok( $elements[1], 'HASH'      );
is( $elements[0]{value}, 'Mimi'   ); 
is( $elements[1]{value}, 'Roscoe' );
}


$plist = Mac::PropertyList::parse_plist( $dict );
isa_ok( $plist, 'HASH'          );
ok( exists $plist->{type}       );
is( $plist->{type}, 'dict'      );
ok( exists $plist->{value}      );
isa_ok( $plist->{value}, 'HASH' );

{
my $hash = $plist->{value};
ok( exists $hash->{Mimi}           );
isa_ok( $hash->{Mimi}, 'HASH'      );
ok( exists $hash->{Mimi}{type}     );
ok( exists $hash->{Mimi}{value}    );
is( $hash->{Mimi}{value}, 'Roscoe' );
}

foreach my $string ( ( $string0_9, $string1_0 ) )
	{
	my $plist = Mac::PropertyList::parse_plist( $string );

	isa_ok( $plist, 'HASH'            );
	ok( exists $plist->{type}         );
	is( $plist->{type}, 'string'      );
	is( $plist->{value}, 'This is it' );
	}
	
my $plist = Mac::PropertyList::parse_plist( $nested_dict );

isa_ok( $plist, 'HASH'            );
ok( exists $plist->{type}         );
is( $plist->{type}, 'dict'        );
ok( exists $plist->{value}        );
isa_ok( $plist->{value}, 'HASH'   );
		
my $hash = $plist->{value}{Mimi};

isa_ok( $plist, 'HASH'                     );
ok( exists $plist->{type}                  );
is( $plist->{type}, 'dict'                 );
ok( exists $plist->{value}                 );
isa_ok( $plist->{value}, 'HASH'            );
is( $hash->{value}{Roscoe}{value}, 1       );
is( $hash->{value}{Boolean}{value}, 'true' );
