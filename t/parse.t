# $Id$
BEGIN { $| = 1; print "1..5\n"; }
END   {print "not ok\n" unless $loaded;}

# Test it loads
use Mac::PropertyList;
$loaded = 1;
print "ok\n";

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

my $string =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
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

	die "Plist structure isn't a hash [$plist]"
		unless( UNIVERSAL::isa( $plist, 'HASH' ) );
	die "Plist doesn't have 'type' key" unless exists $plist->{type};
	die "Plist 'type' key is not 'array' [$$plist{type}]" 
		unless $plist->{type} eq 'array';
	die "Plist doesn't have 'value' key" unless exists $plist->{value};
	die "Plist value is not array ref" 
		unless UNIVERSAL::isa( $plist->{value}, 'ARRAY' );
	
	my @elements = @{ $plist->{value} };
	die "Plist array elements are not hashes [@elements]" 
		unless( UNIVERSAL::isa( $elements[0], 'HASH' )
			and UNIVERSAL::isa( $elements[1], 'HASH' ) );

	die "Plist array elements are wrong [@elements]" 
		unless( $elements[0]{value} eq 'Mimi' 
			and $elements[1]{value} eq 'Roscoe' );

	die "Did not get the right array elements" unless 1;
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {
	my $plist = Mac::PropertyList::parse_plist( $dict );

	die "Plist structure isn't a hash [$plist]"
		unless( UNIVERSAL::isa( $plist, 'HASH' ) );
	die "Plist doesn't have 'type' key" unless exists $plist->{type};
	die "Plist 'type' key is not 'dict' [$$plist{type}]" 
		unless $plist->{type} eq 'dict';
	die "Plist doesn't have 'value' key" unless exists $plist->{value};
	die "Plist value is not hash ref" 
		unless UNIVERSAL::isa( $plist->{value}, 'HASH' );
		
	my $hash = $plist->{value};
		
	die "Hash key is wrong in dict!" 
		unless exists $hash->{Mimi};
	die "Hash value is not a hash ref! [$$hash{Mimi}]" 
		unless UNIVERSAL::isa( $hash->{Mimi}, 'HASH' );
	die "Hash value doesn't have 'type' key" 
		unless exists $hash->{Mimi}{type};
	die "Hash value doesn't have 'value' key" 
		unless exists $hash->{Mimi}{value};
	die "Hash value is not right [$$hash{Mimi}{value}]"
		unless $hash->{Mimi}{value} eq 'Roscoe';
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {
	my $plist = Mac::PropertyList::parse_plist( $string );

	die "Plist structure isn't a hash [$plist]"
		unless( UNIVERSAL::isa( $plist, 'HASH' ) );
	die "Plist doesn't have 'type' key" unless exists $plist->{type};
	die "Plist 'type' key is not 'string' [$$plist{type}]" 
		unless $plist->{type} eq 'string';
	die "Plist has wrong 'value' key [$$plist{value}]" 
		unless $plist->{value} eq 'This is it';
	
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";

eval {
	my $plist = Mac::PropertyList::parse_plist( $nested_dict );

	die "Plist structure isn't a hash [$plist]"
		unless( UNIVERSAL::isa( $plist, 'HASH' ) );
	die "Plist doesn't have 'type' key" unless exists $plist->{type};
	die "Plist 'type' key is not 'dict' [$$plist{type}]" 
		unless $plist->{type} eq 'dict';
	die "Plist doesn't have 'value' key" unless exists $plist->{value};
	die "Plist value is not hash ref" 
		unless UNIVERSAL::isa( $plist->{value}, 'HASH' );
		
	my $hash = $plist->{value}{Mimi};

	die "Hash value isn't a hash [$hash]"
		unless( UNIVERSAL::isa( $hash, 'HASH' ) );
	die "Hash doesn't have 'type' key" unless exists $hash->{type};
	die "Hash 'type' key is not 'dict' [$$hash{type}]" 
		unless $hash->{type} eq 'dict';
	die "Hash doesn't have 'value' key" unless exists $hash->{value};
	die "Hash value is not hash ref" 
		unless UNIVERSAL::isa( $hash->{value}, 'HASH' );
	die "Roscoe value is wrong [$$hash{value}{Roscoe}]" 
		unless $hash->{value}{Roscoe}{value} eq 1;
	die "Boolean value is wrong [$$hash{value}{Boolean}]" 
		unless $hash->{value}{Boolean}{value} eq 'true';
	
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";
