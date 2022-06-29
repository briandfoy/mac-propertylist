#!/usr/bin/env perl

use strict qw(subs vars);
use warnings;

use Test::More;

my $class = 'Mac::PropertyList';
use_ok( $class ) or BAIL_OUT( "$class did not compile\n" );

my $parse_fqname = $class . '::parse_plist';

my $array = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <array>
    <string>Green</string>
    <string>Yellow</string>
  </array>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($array)->as_basic_data,
  [ qw(Green Yellow) ],
  "basic data from an array",
);

my $dict = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Bananas</key>
    <real>59</real>
    <key>Ripeness</key>
    <string>Very Ripe</string>
    <key>Flavor</key>
    <string>Delicious</string>
  </dict>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($dict)->as_basic_data,
  { Bananas => 59, Ripeness => 'Very Ripe', Flavor => 'Delicious' },
  "basic data from a dict",
);

my $nested_array = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <array>
    <string>Green</string>
    <string>Yellow</string>
    <array>
      <string>Orange</string>
      <string>Blue</string>
    </array>
  </array>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($nested_array)->as_basic_data,
  [ 'Green', 'Yellow', [ 'Orange', 'Blue', ], ],
  "basic data from nested arrays",
);

my $nested_dict = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Bananas</key>
    <real>59</real>
    <key>Ripeness</key>
    <string>Very Ripe</string>
    <key>Flavor</key>
    <dict>
      <key>Banananess</key>
      <integer>78</integer>
      <key>Mold</key>
      <integer>12</integer>
      <key>Tarantula</key>
      <integer>51</integer>
    </dict>
  </dict>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($nested_dict)->as_basic_data,
  { Bananas => 59, Ripeness => 'Very Ripe',
    Flavor  => { Banananess => 78, Mold => 12, Tarantula => 51 } },
  "basic data from nested dicts",
);

my $scalar = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <real>59</real>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($scalar)->as_basic_data,
  59,
  "basic data from a scalar",
);

my $string = <<'HERE';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <string>A

  new line</string>
</plist>
HERE

is_deeply(
  &{$parse_fqname}($string)->as_basic_data,
  "A

  new line",
  "basic data from a string with embedded new lines",
);

done_testing();
