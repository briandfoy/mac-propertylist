# $Id$
BEGIN { $| = 1; print "1..4\n"; }
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

my $nested_dict_alt =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Boolean</key>
		<true/>
		<key>Roscoe</key>
		<integer>1</integer>
	</dict>
</dict>
</plist>
HERE

foreach my $start ( ( $array, $dict ) )
	{
	eval {
		my $plist = Mac::PropertyList::parse_plist( $start );
	
		my $string = Mac::PropertyList::plist_as_string( $plist );
		
		print STDERR "\n$string\n" if $ENV{DEBUG};

		die "Array ending string is not the same as starting string!"
			unless $start eq $string;
		};
	print STDERR $@ if $@;
	print $@ ? 'not ' : '', "ok\n";
	}

eval {
	my $plist = Mac::PropertyList::parse_plist( $nested_dict );

	my $string = Mac::PropertyList::plist_as_string( $plist );
	
	print STDERR "\n$string\n" if $ENV{DEBUG};

	die "Array ending string is not the same as starting string!"
		unless( $nested_dict eq $string or $nested_dict_alt eq $string );
	};
print STDERR $@ if $@;
print $@ ? 'not ' : '', "ok\n";
