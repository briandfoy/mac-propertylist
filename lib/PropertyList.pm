# $Id$
package Mac::PropertyList;
use strict;

use vars qw($ERROR);

=head1 NAME

Mac::PropertyList - work with Mac plists at a low level

=head1 SYNOPSIS

	use Mac::PropertyList;
	
	my $data = parse_plist( $text );

	my $text = plist_as_string( $data );
	
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
the XML they are empty elements.  Mac::PropertyList
makes them look not-empty.  This may seem wierd, but
it saved hours of work in the implementation.

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

my $Debug = 1;

use Text::Balanced qw(gen_extract_tagged extract_tagged);

my %Readers = (
	"<dict>"    => \&read_dict,
	"<string>"  => \&read_string,
	"<date>"    => \&read_date,
	"<real>"    => \&read_real,
	"<integer>" => \&read_integer,
	"<string>"  => \&read_string,
	"<array>"   => \&read_array,
	"<data>"    => \&read_data,
	"<true>"    => \&read_true,
	"<false>"   => \&read_false,
	);

my %Writers = (
	"dict"    => \&write_dict,
	"string"  => \&write_string,
	"date"    => \&write_date,
	"real"    => \&write_real,
	"integer" => \&write_integer,
	"string"  => \&write_string,
	"array"   => \&write_array,
	"data"    => \&write_data,
	"true"    => \&write_true,
	"false"   => \&write_false,
	);

my $Options = {ignore => ['<true/>', '<false/>']};
my $Key = gen_extract_tagged(  "<key>", "</key>", undef, $Options );

=head1 FUNCTIONS

=over 4

=item parse_plist( TEXT )

Parse the XML plist in TEXT and return the Mac::PropertyList
data structure.

=cut

sub parse_plist
	{
	my $text = shift;
	
	$text =~ s|<true/>|<true>true</true>|g;
	$text =~ s|<false/>|<false>false</false>|g;

	my @plist = extract_tagged( $text, 
		'<plist version="1.0">', "</plist>",
		 '(?s)<\?xml.*(?=<plist.*?>)', $Options );

	if( $@ )
		{
		$ERROR = "Could not extract plist!\n" . $@->{error};
		return;
		}

	my @object = extract_tagged( $plist[4], 
		undef, undef, undef, $Options );
	
	unless( exists $Readers{$object[3]} )
		{
		$ERROR = "Not a plist object [$object[3]]!";
		return;
		}

	print STDERR "Found $object[3]\n" if $Debug > 1;
	
	my $plist = $Readers{$object[3]}->($object[4]);

	return $plist;
	}

sub _hash { { type => $_[0], value => $_[1] } }

sub read_string  { _hash( 'string',  $_[0] ) }
sub read_integer { _hash( 'integer', $_[0] ) }
sub read_date    { _hash( 'date',    $_[0] ) }
sub read_real    { _hash( 'real',    $_[0] ) }
sub read_float   { _hash( 'float',   $_[0] ) }
sub read_true    { _hash( 'true',    $_[0] ) }
sub read_false   { _hash( 'false',   $_[0] ) }

sub read_dict
	{
	my $data = shift;
	print STDERR "Processing dict\n" if $Debug > 1;
	
	my %hash;
	
	while(1)
		{
		my @key = $Key->($data);
		last if $@;
		print STDERR "Found key with value [$key[4]]\n" if $Debug > 1;
		my @object = extract_tagged( $data, undef, undef, undef, $Options );
		print STDERR "Found object [$object[3]]\n" if $Debug > 1;
		my $value = $Readers{$object[3]}->($object[4]);
			
		$hash{$key[4]} = $value;
		}
		
	return _hash( 'dict', \%hash );
	}

sub read_array
	{
	my $array = shift;
	
	my @array = ();

	while(1)
		{
		my @object = extract_tagged( $array, undef, undef, undef, $Options );
		last if $@;
		my $value = $Readers{$object[3]}->($object[4]);
		push @array, $value;
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

=item write_plist( PLIST_HASH )

UNIMPLEMENTED

=cut

sub plist_as_string
	{
	my $ref = shift;
	
	require Carp;
	
	carp( "plist_as_string is unimplemented" );
	}
	
sub _string { "<$_[0]>$_[1]</$_[0]>" }

sub write_string  { _string( 'string',  $_[0] ) }
sub write_integer { _string( 'integer', $_[0] ) }
sub write_date    { _string( 'date',    $_[0] ) }
sub write_real    { _string( 'real',    $_[0] ) }
sub write_float   { _string( 'float',   $_[0] ) }
sub write_true    { "<true/>" }
sub write_false   { "<false/>" }

sub write_data
	{
	my $string = shift;
	
	require MIME::Base64;
	
	$string = MIME::Base64::encode_base64($string);

	return _string( 'data', $string );
	}

sub write_array
	{
	my $hash = shift;
	
	my( $type, $array ) = @{ $hash }{ qw( type value ) };
	return unless $type eq 'array';
	
	my $string = "<array>\n";
	
	foreach my $element ( @$array )
		{
		my( $type, $value ) = @{ $element }{ qw( type value ) };
		
		my $bit = $Writers{$type}->( $value );
		
		$bit =~ s/$/\t/gm;
		
		$string .= $bit . "\n";
		}
	
	$string .= "</array>\n";
	
	return $string;		
	}

sub write_dict
	{
	my $hash = shift;
	
	my( $type, $dict ) = @{ $hash }{ qw( type value ) };
	return unless $type eq 'dict';
	
	my $string = "<dict>\n";
	
	foreach my $key ( keys %$dict )
		{
		my( $type, $value ) = @{ $dict->{$key} }{ qw( type value ) };
		
		my $bit  = _string( 'key', $key ) . "\n";
		   $bit .= $Writers{$type}->( $value ) . "\n";
		
		$bit =~ s/$/\t/gm;
		
		$string .= $bit;
		}
	
	$string .= "</dict>\n";
	
	return $string;		
	}

=back

=head1 TO DO

* actually test the write_* stuff

=head1 BUGS

* probably a lot, but it's too soon to know about them

=head1 AUTHOR

brian d foy, E<lt>brian d foyE<gt>

=head1 SEE ALSO

http://www.apple.com/DTDs/PropertyList-1.0.dtd

=cut

"See why 1984 won't be like 1984";
