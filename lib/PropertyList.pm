# $Id$
package Mac::PropertyList;
use strict;

use vars qw($ERROR $XML_head $XML_foot $VERSION);

$VERSION = 0.07;

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

my $Debug = $ENV{PLIST_DEBUG};

use Text::Balanced qw(gen_extract_tagged extract_tagged);

$XML_head =<<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
XML

$XML_foot =<<"XML";
</plist>
XML

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

sub _strip_leading_space
	{
	my $ref = shift;
	
	$$ref =~ s/^\s*//;	
	}
	
sub _get_next_tag
	{
	my $ref = shift;
	_strip_leading_space($ref);
	
	my( $tag ) = $$ref =~ m/^(<.*?>)/g;
	
	return $tag;
	}
	
sub parse_plist
	{
	my $text = shift;
	
	$text =~ s|<true/>|<true>true</true>|g;
	$text =~ s|<false/>|<false>false</false>|g;

	# we can handle either 0.9 or 1.0
	$text =~ s|^<\?xml.*?>\s*<!DOC.*>\s*<plist.*?>\s*||;
	$text =~ s|\s*</plist>\s*$||;
	
	my $plist = do {
		if( $text =~ s/^\s*<(array|dict)>\s*// )
			{
			my $type = $1;
			$text =~ s|\s*</$type>\s*$||;
			$Readers{"<$type>"}->( \$text );
			}
		else
			{
			my @object = extract_tagged( $text, 
				undef, undef, undef, $Options );
			
			unless( exists $Readers{$object[3]} )
				{
				$ERROR = "Not a plist object [$object[3]]!";
				return;
				}
				
			print STDERR "Found $object[3]\n" if $Debug > 1;
			
			$Readers{$object[3]}->($object[4]);
			}
		};		

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

sub _read_tag
	{
	my $tag = shift;
	my $ref = shift;
	
	$$ref = s|\s*<$tag>(.*?)</$tag>\s*||g;
	
	return $Readers{"<$tag>"}->($1);
	}
	
sub read_string  { _hash( 'string',  $_[0] ) }
sub read_integer { _hash( 'integer', $_[0] ) }
sub read_date    { _hash( 'date',    $_[0] ) }
sub read_real    { _hash( 'real',    $_[0] ) }
sub read_true    { _hash( 'true',    $_[0] ) }
sub read_false   { _hash( 'false',   $_[0] ) }

sub read_next
	{
	my $ref = shift;
	
	my $value = do {
		my $tag;
		my $value;
		if( $$ref =~ m[^\s*<(string|date|real|integer|data|true|false)>\s*(.*?)\s*</\1>]s )
			{
			$tag   = $1;
			$value = $2;
			print STDERR "read_next: Found value type $1\n" if $Debug > 1;
			$$ref =~ s|\s*<$tag>\s*(.*?)\s*</$tag>\s*||s;
			_print_next_bit( $ref ) if $Debug > 1;
			$Readers{"<$tag>"}->($value);
			}
		elsif( $$ref =~ m[^\s*<(dict|array)>(.*?)</\1>]s and $tag = $1 and $value = $2 and $value !~ m/<$tag>/ )
			{
			print STDERR "dict: Found value type $1 without nested $1\n" if $Debug > 1;
			$$ref =~ s|\s*<$tag>\s*(.*?)\s*</$tag>\s*||s;
			_print_next_bit( $ref ) if $Debug > 1;
			$Readers{"<$tag>"}->(\$value);
			}
		};

	}
	
sub read_dict
	{
	my $ref = shift;
	print STDERR "Processing dict\n" if $Debug > 1;
	
	my %hash;
	
	while( $$ref =~ s|^\s*<key>(.*?)</key>\s*||s )
		{
		my $key = $1;
						
		$hash{$key} = read_next( $ref );
		}
		
	return _hash( 'dict', \%hash );
	}

sub _print_next_bit
	{
	my $ref = shift;
	my $sub = (caller(1))[3];
	$sub =~ s/.*:://;
	
	print STDERR "$sub: Next bit is [" . substr( $$ref, 0, 10 ) . "]\n";
	}
	
sub read_array
	{
	my $ref = shift;
	
	print STDERR "Processing array\n" if $Debug > 1;
	
	my @array = ();

	while( $$ref )
		{
		_print_next_bit( $ref ) if $Debug > 1;
		push @array, read_next( $ref )
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

=head1 TO DO

* actually test the write_* stuff

=head1 BUGS

* i've taken some shortcuts with the parsing, since balanced text parsing 
can be really slow.  at the moment this module can't handle more than
one level of nest dicts or arrays.  this breaks on some application's
files:

	com.apple.DiskCopy.plist
	com.apple.dock.plist
	com.apple.Preview.plist
	com.apple.TextEdit.plist
	org.aegidian.yaxjournal.plist
	FruitMenu.prefPane/Contents/Resources/Library.plist
	FruitMenu.prefPane/Contents/Resources/Presets.plist


=head1 AUTHOR

brian d foy, E<lt>bdfoy@cpan.orgE<gt>

=head1 SEE ALSO

http://www.apple.com/DTDs/PropertyList-1.0.dtd

=cut

"See why 1984 won't be like 1984";
