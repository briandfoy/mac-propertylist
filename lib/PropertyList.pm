# $Id$
package Mac::PropertyList;
use strict;

use vars qw($ERROR $XML_head $XML_foot $VERSION);

$VERSION = 0.11;

=head1 NAME

Mac::PropertyList - work with Mac plists at a low level

=head1 SYNOPSIS

	use Mac::PropertyList;

	my $data  = parse_plist( $text );

	my $text  = plist_as_string( $data );

	my $plist = create_from_hash( \%hash );

=head1 DESCRIPTION

This module is a low-level interface to the Mac OS X
Property List (plist) format.  You probably shouldn't use this
in applications---build interfaces on top of this so
you don't have to put all the heinous multi-level hash
stuff where people can see it.

You can parse a plist file and get back a data structure.
You can take that data structure and get back the plist
as XML.  If you want to change the structure inbetween
that's your business. :)

=head2 The Property List format

The MacOS X Property List format is simple XML.  You
can read the DTD to get the details.

	http://www.apple.com/DTDs/PropertyList-1.0.dtd

One big problem exists---its dict type uses a flat
structure to list keys and values so that values
are only associated with their keys by their position
in the file rather than by the structure of the DTD.
This problem is the major design hinderance in this
module.  A smart XML format would have made things
much easier.

If the parse_plist encounters an empty key tag in a dict
structure (i.e. C<< <key></key> >> ) the function dies.
This is a misfeature which I want to correct in future
versions.

=head2 The Mac::PropertyList data structure

A plist can have one or more of any of the plist
objects, and we have to remember the type of thing
so we can go back to the XML format.  Perl treats
numbers and strings the same, but the plist format
doesn't.

Therefore, everything Mac::PropertyList creates is
an anonymous hash.  The key "type" is the plist
object type, and the value "value" is the data.

The hash for a string object looks like

	{
	type  => 'string',
	value => 'this is the string'
	}

The structure for the date, data, integer, float, and
real look the same.

The plist objects true and false are wierd since in
the XML they are empty elements, but in this data
structure Mac::Property list pretends they are not
so it can avoid a special case.

	{
	type  => 'true',
	value => 'true'
	}

The hash for a plist array object looks the same,
but its value is an anonymous array which holds
more plist objects (which are in turn hashes).

	{
	type  => 'array',
	value => [
		{ type => integer, value => 1 },
		{ type => string,  value => 'Foo' }
		]
	}

The hash for a plist dict object is similar.  The values
of the keys are in turn plist objects again.

	{
	type  => 'dict',
	value => {
		"Bar" => { type => string,  value => 'Foo' }
		}
	}

From here you can make any combination of the above
structures.  I do not intend that you should have to
know any of this at the application level.  People
should create another layer on top of this to provide
a simple interface to a particular plist file.

Run a small script against your favorite plist file
then dump the results with Data::Dumper.  That's
what the real deal looks like.

=cut

my $Debug = $ENV{PLIST_DEBUG} || 0;

$XML_head =<<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
XML

$XML_foot =<<"XML";
</plist>
XML

my %Readers = (
	"dict"    => \&read_dict,
	"string"  => \&read_string,
	"date"    => \&read_date,
	"real"    => \&read_real,
	"integer" => \&read_integer,
	"string"  => \&read_string,
	"array"   => \&read_array,
	"data"    => \&read_data,
	"true"    => \&read_true,
	"false"   => \&read_false,
	);

my %Writers = (
	"dict"    => \&write_dict,
	"string"  => \&write_string,
	"date"    => \&write_date,
	"real"    => \&write_real,
	"integer" => \&write_integer,
	"array"   => \&write_array,
	"data"    => \&write_data,
	"true"    => \&write_true,
	"false"   => \&write_false,
	);

my $Options = {ignore => ['<true/>', '<false/>']};

=head1 FUNCTIONS

=over 4

=item parse_plist( TEXT )

Parse the XML plist in TEXT and return the Mac::PropertyList
data structure.

=cut

sub parse_plist
	{
	my $text = shift;

	# we can handle either 0.9 or 1.0
	$text =~ s|^<\?xml.*?>\s*<!DOC.*>\s*<plist.*?>\s*||;
	$text =~ s|\s*</plist>\s*$||;

	my $plist = read_next( \$text );

	return $plist;
	}

=item create_from_hash( HASH_REF )

Create a plist dictionary from the hash reference.

The values of the hash can only be simple scalars---not
references.  Reference values are silently ignored.

Returns a string representing the hash in the plist format.

=cut

sub create_from_hash
	{
	my $hash  = shift;

	return unless UNIVERSAL::isa( $hash, 'HASH' );

	my $string = "$XML_head<dict>\n";

	foreach my $key ( keys %$hash )
		{
		my( $type, $value ) = ( 'string', $hash->{$key} );

		next if ref $value;

		my $bit  = _string( 'key', $key ) . "\n";
		   $bit .= $Writers{$type}->( $value ) . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= "</dict>\n$XML_foot";

	return $string;
	}

sub _hash { { type => $_[0], value => $_[1] } }

sub read_string  { _hash( 'string',  $_[0] ) }
sub read_integer { _hash( 'integer', $_[0] ) }
sub read_date    { _hash( 'date',    $_[0] ) }
sub read_real    { _hash( 'real',    $_[0] ) }
sub read_true    { _hash( 'true',  'true'  ) }
sub read_false   { _hash( 'false', 'false' ) }

sub read_next
	{
	my $ref = shift;

	my $value = do {
		my $tag;
		my $value;
		if( $$ref =~ s[^\s* < (string|date|real|integer|data) >
			\s*(.*?)\s* </\1> ][]sx )
			{
			print STDERR "read_next: Found value type [$1] with value [$2]\n"
				if $Debug > 1;
			$Readers{$1}->( $2 );
			}
		elsif( $$ref =~ s[^\s* < (dict|array) > ][]x )
			{
			print STDERR "\$1 is [$1]\n" if $Debug > 1;
			$Readers{$1}->( $ref );
			}
		# these next two are some wierd cases i found in the iPhoto Prefs
		elsif( $$ref =~ s[^\s* < dict / > ][]x )
			{
			return _hash( 'dict', {} );
			}
		elsif( $$ref =~ s[^\s* < array / > ][]x )
			{
			return _hash( 'array', [] );
			}
		elsif( $$ref =~ s[^\s* < (true|false) /> ][]x )
			{
			print STDERR "\$1 is [$1]\n" if $Debug > 1;
			$Readers{$1}->();
			}
		};

	}

sub read_dict
	{
	my $ref = shift;
	print STDERR "Processing dict\n" if $Debug > 1;

	my %hash;

	while( not $$ref =~ s|^\s*</dict>|| )
		{
		$$ref =~ s[^\s*<key>(.*?)</key>][]s;
		print STDERR "read_dict: key is [$1]\n" if $Debug > 1;
		die "Could not read key!" unless defined $1;
		my $key = $1;
		$hash{ $key } = read_next( $ref );
		}

	return _hash( 'dict', \%hash );
	}

sub read_array
	{
	my $ref = shift;
	print STDERR "Processing array\n" if $Debug > 1;

	my @array = ();

	while( not $$ref =~ s|^\s*</array>|| )
		{
		push @array, read_next( $ref );
		}

	return _hash( 'array', \@array );
	}

sub read_data
	{
	my $string = shift;

	require MIME::Base64;

	$string = MIME::Base64::decode_base64($string);

	return _hash( 'data', $string );
	}

sub plist_as_string
	{
	my $hash = shift;

	my( $type, $value ) = @{ $hash }{ qw( type value ) };

	my $string = $XML_head;

	$string .= $Writers{$type}->($value) . "\n";

	$string .= $XML_foot;

	return $string;
	}

sub _string { "<$_[0]>$_[1]</$_[0]>" }

sub write_string  { _string( 'string',  $_[0] ) }
sub write_integer { _string( 'integer', $_[0] ) }
sub write_date    { _string( 'date',    $_[0] ) }
sub write_real    { _string( 'real',    $_[0] ) }
sub write_true    { "<true/>" }
sub write_false   { "<false/>" }

sub write_data($)
	{
	my $string = shift;

	require MIME::Base64;

	$string = MIME::Base64::encode_base64($string);

	return _string( 'data', $string );
	}

sub write_array
	{
	my $array = shift;

	my $string = "<array>\n";

	foreach my $element ( @$array )
		{
		my( $type, $value ) = @{ $element }{ qw( type value ) };

		my $bit = $Writers{$type}->( $value );

		$bit =~ s/^/\t/gm;

		$string .= $bit . "\n";
		}

	$string .= "</array>";

	return $string;
	}

sub write_dict
	{
	my $dict  = shift;

	my $string = "<dict>\n";

	foreach my $key ( keys %$dict )
		{
		my( $type, $value ) = @{ $dict->{$key} }{ qw( type value ) };

		my $bit  = _string( 'key', $key ) . "\n";
		   $bit .= $Writers{$type}->( $value ) . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= "</dict>";

	return $string;
	}

=back

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	https://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 CREDITS

Thanks to Chris Nandor for general Mac kung fu and Chad Walker
for help figuring out the recursion for nested structures.

=head1 TO DO

* actually test the write_* stuff

* the read_dict method dies() if the key is not defined.  i do
not like to die from functions.

* do this from a filehandle or a scalar reference instead of a scalar
	+ generate closures to handle the work.

=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 SEE ALSO

http://www.apple.com/DTDs/PropertyList-1.0.dtd

=cut

"See why 1984 won't be like 1984";
