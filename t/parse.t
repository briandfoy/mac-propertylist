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

isa_ok( $plist, 'HASH' );
ok( exists $plist->{type},   'type key exists for array'  );
is( $plist->{type}, 'array', 'Item is an array type'      );
ok( exists $plist->{value},  'value key exists for array' );
isa_ok( $plist->{value}, 'ARRAY' );

{	
my @elements = @{ $plist->{value} };
isa_ok( $elements[0], 'HASH' );
isa_ok( $elements[1], 'HASH' );
is( $elements[0]{value}, 'Mimi',   'Mimi string is right'   ); 
is( $elements[1]{value}, 'Roscoe', 'Roscoe string is right' );
}


$plist = Mac::PropertyList::parse_plist( $dict );
isa_ok( $plist, 'HASH' );
ok( exists $plist->{type},  'type key exists for dict'  );
is( $plist->{type}, 'dict', 'item is a dict type'       );
ok( exists $plist->{value}, 'value key exists for dict' );
isa_ok( $plist->{value}, 'HASH' );

{
my $hash = $plist->{value};
ok( exists $hash->{Mimi},           'Mimi key exists for dict'         );
isa_ok( $hash->{Mimi}, 'HASH' );
ok( exists $hash->{Mimi}{type},     'type key exists for Mimi string'  );
ok( exists $hash->{Mimi}{value},    'value key exists for Mimi string' );
is( $hash->{Mimi}{value}, 'Roscoe', 'Mimi string has right value'      );
}

foreach my $string ( ( $string0_9, $string1_0 ) )
	{
	my $plist = Mac::PropertyList::parse_plist( $string );

	isa_ok( $plist, 'HASH' );
	ok( exists $plist->{type},         'type key exists for string'          );
	is( $plist->{type}, 'string',      'type key has right value for string' );
	is( $plist->{value}, 'This is it', 'value is right for string'           );
	}
	
my $plist = Mac::PropertyList::parse_plist( $nested_dict );

isa_ok( $plist, 'HASH'            );
ok( exists $plist->{type},  'type key exists for nested dict'          );
is( $plist->{type}, 'dict', 'type key has right value for nested dict' );
ok( exists $plist->{value}, 'value key exists for nested dict'         );
isa_ok( $plist->{value}, 'HASH'   );
		
my $hash = $plist->{value}{Mimi};

isa_ok( $plist, 'HASH'                     );
ok( exists $plist->{type},  'type key exists for interior nested dict'  );
is( $plist->{type}, 'dict', 'item is a dict type'                       );
ok( exists $plist->{value}, 'value key exists for interior nested dict' );
isa_ok( $plist->{value}, 'HASH'            );
is( $hash->{value}{Roscoe}{value}, 1,       'Roscoe string has right value'   );
is( $hash->{value}{Boolean}{value}, 'true', 'Boolean string has right value'  );
