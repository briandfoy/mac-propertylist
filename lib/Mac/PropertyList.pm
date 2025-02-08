use v5.10;
use strict;
use warnings;

package Mac::PropertyList;

use vars qw($ERROR);
use Carp qw(croak carp);
use Data::Dumper;
use Scalar::Util qw(set_prototype);
use XML::Entities;

use Mac::PropertyList::array;
use Mac::PropertyList::Boolean;
use Mac::PropertyList::Container;
use Mac::PropertyList::data;
use Mac::PropertyList::date;
use Mac::PropertyList::dict;
use Mac::PropertyList::false;
use Mac::PropertyList::integer;
use Mac::PropertyList::Item;
use Mac::PropertyList::LineListSource;
use Mac::PropertyList::real;
use Mac::PropertyList::Scalar;
use Mac::PropertyList::Source;
use Mac::PropertyList::string;
use Mac::PropertyList::TextSource;
use Mac::PropertyList::false;
use Mac::PropertyList::true;
use Mac::PropertyList::uid;
use Mac::PropertyList::ustring;

use Exporter qw(import);

my @shortcuts = qw(
	pl_array
	pl_data
	pl_date
	pl_dict
	pl_false
	pl_integer
	pl_real
	pl_string
	pl_true
	pl_uid
	);
my @parsers = qw(
	parse_plist
	parse_plist_fh
	parse_plist_file
	);
my @creators = qw(
	create_from_hash
	create_from_array
	create_from_string
	);

use vars qw(@EXPORT_OK %EXPORT_TAGS);

@EXPORT_OK = (
	@creators,
	@parsers,
	@shortcuts,
	qw(
		plist_as_string
		)
	);

%EXPORT_TAGS = (
	'all'       => \@EXPORT_OK,
	'creators'  => \@creators,
	'parsers'   => \@parsers,
	'shortcuts' => \@shortcuts,
	);

our $MORE_ARGS_ERROR = 'Too many arguments for Mac::PropertyList::%s';
our $ZERO_ARGS_ERROR = 'Not enough arguments for Mac::PropertyList::%s';

our $VERSION = '1.603_02';


=encoding utf8

=head1 NAME

Mac::PropertyList - work with Mac plists at a low level

=head1 SYNOPSIS

	use Mac::PropertyList qw(:all);

	my $data  = parse_plist( $text );
	my $perl  = $data->as_perl;

		# == OR ==
	my $data  = parse_plist_file( $filename );

		# == OR ==
	open my( $fh ), $filename or die "...";
	my $data  = parse_plist_fh( $fh );


	my $text  = plist_as_string( $data );

	my $plist = create_from_hash(  \%hash  );
	my $plist = create_from_array( \@array );

	my $plist = Mac::PropertyList::dict->new( \%hash );

	my $perl  = $plist->as_perl;

=head1 DESCRIPTION

This module is a low-level interface to the Mac OS X Property List
(plist) format in either XML or binary. You probably shouldn't use
this in applications–build interfaces on top of this so you don't have
to put all the heinous multi-level object stuff where people have to
look at it.

You can parse a plist file and get back a data structure. You can take
that data structure and get back the plist as XML. If you want to
change the structure inbetween that's your business. :)

You don't need to be on Mac OS X to use this. It simply parses and
manipulates a text format that Mac OS X uses.

If you need to work with the old ASCII or newer JSON formet, you can
use the B<plutil> tool that comes with MacOS X:

	% plutil -convert xml1 -o ExampleBinary.xml.plist ExampleBinary.plist

Or, you can extend this module to handle those formats (and send a pull
request).

=head2 The Property List format

The MacOS X Property List format is simple XML. You can read the DTD
to get the details.

	http://www.apple.com/DTDs/PropertyList-1.0.dtd

One big problem exists—its dict type uses a flat structure to list
keys and values so that values are only associated with their keys by
their position in the file rather than by the structure of the DTD.
This problem is the major design hinderance in this module. A smart
XML format would have made things much easier.

If the parse_plist encounters an empty key tag in a dict structure
(i.e. C<< <key></key> >> ) the function croaks.

=head2 The Mac::PropertyList classes

A plist can have one or more of any of the plist objects, and we have
to remember the type of thing so we can go back to the XML format.
Perl treats numbers and strings the same, but the plist format
doesn't.

Therefore, everything C<Mac::PropertyList> creates is an object of some
sort. Container objects like C<Mac::PropertyList::array> and
C<Mac::PropertyList::dict> hold other objects.

There are several types of objects:

	Mac::PropertyList::string
	Mac::PropertyList::data
	Mac::PropertyList::real
	Mac::PropertyList::integer
	Mac::PropertyList::uid
	Mac::PropertyList::date
	Mac::PropertyList::array
	Mac::PropertyList::dict
	Mac::PropertyList::true
	Mac::PropertyList::false

Note that the Xcode property list editor abstracts the C<true> and
C<false> objects as just C<Boolean>. They are separate tags in the
plist format though.

Construct these values by calling C<new> with the value:

	my %hash = (
		leopard  => Mac::PropertyList::integer->new(137),
		cougar   => Mac::PropertyList::string->new('Dog Cow'),
		);

The elements in an array or the values in a dict need to know their
type:

	my $dict = Mac::PropertyList::dict->new(\%hash);

There are also shortcuts for these:

	my %hash = (
		leopard  => pl_util(137),
		cougar   => pl_string('Dog Cow'),
		);

	my $dict = pl_dict( \$hash );

=over 4

=item * pl_dict( ARGS )

A shortcut for C<Mac::PropertyList::dict->new(ARGS)>.

=cut

sub pl_dict {
	Mac::PropertyList::dict->new(@_);
	}

=item * pl_array( ARGS )

A shortcut for C<Mac::PropertyList::array->new(ARGS)>.

=cut

sub pl_array {
	Mac::PropertyList::array->new(@_);
	}

=item * pl_data( DATA )

A shortcut for C<Mac::PropertyList::data->new(DATA)>. This takes
exactly one argument and will croak otherwise.

=cut

sub pl_data {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_data';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_data';
		}

	Mac::PropertyList::data->new($_[0]);
}

=item * pl_date(DATE)

A shortcut for C<Mac::PropertyList::date->new(DATE)>. This takes
exactly one argument and will croak otherwise.

=cut

sub pl_date {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_data';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_data';
		}

	Mac::PropertyList::date->new($_[0]);
}

=item * pl_false()

A shortcut for C<Mac::PropertyList::false->new()>. This takes
no arguments and will croak otherwise.

=cut

sub pl_false {
	if( @_ > 0 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_false';
		}

	Mac::PropertyList::false->new;
}

=item * pl_integer( INT )

A shortcut for C<Mac::PropertyList::integer->new(INT)>. This takes
exactly one argument and will croak otherwise.

=cut

sub pl_integer {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_data';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_data';
		}

	Mac::PropertyList::integer->new(@_);
}

=item * pl_real(NUM)

A shortcut for C<Mac::PropertyList::real->new(NUM)>. This takes
exactly one argument and will croak otherwise.

=cut

sub pl_real {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_real';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_real';
		}

	Mac::PropertyList::real->new(@_);
}

=item * pl_string(STRING)

A shortcut for C<Mac::PropertyList::string->new(STRING)>. This takes
exactly one argument and will croak otherwise.

=cut

sub pl_string {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_string';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_string';
		}

	Mac::PropertyList::string->new(@_);
}

=item * pl_true()

A shortcut for C<Mac::PropertyList::true->new()>. This takes
no arguments and will croak otherwise.

=cut

sub pl_true {
	if( @_ > 0 ) {
		croak sprintf $MORE_ARGS_ERROR, 'pl_true';
		}

	Mac::PropertyList::true->new;
}

=item * pl_uid(UID)

A shortcut for C<Mac::PropertyList::uid->new(UID)>.

=cut

sub pl_uid {
	if( @_ > 1 ) {
		croak  sprintf $MORE_ARGS_ERROR, 'pl_uid';
		}
	elsif( @_ == 0 ) {
		croak sprintf $ZERO_ARGS_ERROR, 'pl_uid';
		}

	Mac::PropertyList::uid->new(@_);
}

=back

=head2 Methods

=over 4

=item new( VALUE )

Create the object.

=item value

Access the value of the object. At the moment you cannot change the
value

=item type

Access the type of the object (string, data, etc)

=item write

Create a string version of the object, recursively if necessary.

=item as_perl

Turn the plist data structure, which is decorated with extra
information, into a lean Perl data structure without the value type
information or blessed objects.

=back

=cut

my $Debug = $ENV{PLIST_DEBUG} || 0;

my %Readers = (
	"dict"    => \&read_dict,
	"string"  => \&read_string,
	"date"    => \&read_date,
	"real"    => \&read_real,
	"integer" => \&read_integer,
	"array"   => \&read_array,
	"data"    => \&read_data,
	"true"    => \&read_true,
	"false"   => \&read_false,
	);

my $Options = {ignore => ['<true/>', '<false/>']};

=head1 FUNCTIONS

These functions are available for individual or group import. Nothing
will be imported unless you ask for it.

	use Mac::PropertyList qw( parse_plist );

	use Mac::PropertyList qw( :all );

=head2 Things that parse

=over 4

=item parse_plist( TEXT )

Parse the XML plist in TEXT and return the C<Mac::PropertyList>
object.

=cut

# This will change to parse_plist_ref when we create the dispatcher

sub parse_plist {
	my $text = shift;

	my $plist = do {
		if( $text =~ /\A<\?xml/ ) { # XML plists
			$text =~ s/<!--(?:[\d\D]*?)-->//g;
			# we can handle either 0.9 or 1.0
			$text =~ s|^<\?xml.*?>\s*<!DOC.*>\s*<plist.*?>\s*||;
			$text =~ s|\s*</plist>\s*$||;

			my $text_source = Mac::PropertyList::TextSource->new( $text );
			read_next( $text_source );
			}
		elsif( $text =~ /\Abplist/ ) { # binary plist
			require Mac::PropertyList::ReadBinary;
			my $parser = Mac::PropertyList::ReadBinary->new( \$text );
			$parser->plist;
			}
		else {
			croak( "This doesn't look like a valid plist format!" );
			}
		};
	}

=item parse_plist_fh( FILEHANDLE )

Parse the XML plist from FILEHANDLE and return the C<Mac::PropertyList>
data structure. Returns false if the arguments is not a reference.

You can do this in a couple of ways. You can open the file with a
lexical filehandle (since Perl 5.6).

	open my( $fh ), $file or die "...";
	parse_plist_fh( $fh );

Or, you can use a bareword filehandle and pass a reference to its
typeglob. I don't recommmend this unless you are using an older
Perl.

	open FILE, $file or die "...";
	parse_plist_fh( \*FILE );

=cut

sub parse_plist_fh {
	my $fh = shift;

	my $text = do { local $/; <$fh> };

	parse_plist( $text );
	}

=item parse_plist_file( FILE_PATH )

Parse the XML plist in FILE_PATH and return the C<Mac::PropertyList>
data structure. Returns false if the file does not exist.

Alternately, you can pass a filehandle reference, but that just
calls C<parse_plist_fh> for you.

=cut

sub parse_plist_file {
	my $file = shift;

	if( ref $file ) { return parse_plist_fh( $file ) }

	unless( -e $file ) {
		croak( "parse_plist_file: file [$file] does not exist!" );
		return;
		}

	my $text = do { local $/; open my($fh), '<:raw', $file; <$fh> };

	parse_plist( $text );
	}

=item create_from_hash( HASH_REF )

Create a plist dictionary from the hash reference.

The values of the hash can only be simple scalars–not references.
Reference values are silently ignored.

Returns a string representing the hash in the plist format.

=cut

sub create_from_hash {
	my $hash  = shift;

	unless( ref $hash eq ref {} ) {
		carp "create_from_hash did not get an hash reference";
		return;
		}

	my $string = XML_head() . Mac::PropertyList::dict->write_open . "\n";

	foreach my $key ( keys %$hash ) {
		next if ref $hash->{$key};

		my $bit   = Mac::PropertyList::dict->write_key( $key ) . "\n";
		my $value = Mac::PropertyList::string->new( $hash->{$key} );

		$bit  .= $value->write . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= Mac::PropertyList::dict->write_close . "\n" . XML_foot();

	return $string;
	}

=item create_from_array( ARRAY_REF )

Create a plist array from the array reference.

The values of the array can only be simple scalars–not references.
Reference values are silently ignored.

Returns a string representing the array in the plist format.

=cut

sub create_from_array {
	my $array  = shift;

	unless( ref $array eq ref [] ) {
		carp "create_from_array did not get an array reference";
		return;
		}

	my $string = XML_head() . Mac::PropertyList::array->write_open . "\n";

	foreach my $element ( @$array ) {
		my $value = Mac::PropertyList::string->new( $element );

		my $bit  .= $value->write . "\n";
		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= Mac::PropertyList::array->write_close . "\n" . XML_foot();

	return $string;
	}

=item create_from_string( STRING )

Returns a string representing the string in the plist format.

=cut

sub create_from_string {
	my $string  = shift;

	unless( ! ref $string ) {
		carp "create_from_string did not get a string";
		return;
		}

	return
		XML_head() .
		Mac::PropertyList::string->new( $string )->write .
		"\n" . XML_foot();
	}

=item create_from

Dispatches to either C<create_from_array>, C<create_from_hash>, or
C<create_from_string> based on the argument. If none of those fit,
this C<croak>s.

=cut

sub create_from {
	my $thingy  = shift;

	return do {
		if(      ref $thingy eq ref [] ) { &create_from_array  }
		elsif(   ref $thingy eq ref {} ) { &create_from_hash   }
		elsif( ! ref $thingy eq ref {} ) { &create_from_string }
		else {
			croak "Did not recognize argument! Must be a string, or reference to a hash or array";
			}
		};
	}

=item read_string

=item read_data

=item read_integer

=item read_date

=item read_real

=item read_true

=item read_false

Reads a certain sort of property list data

=cut

sub read_string  { Mac::PropertyList::string ->new( XML::Entities::decode( 'all', $_[0] ) )  }
sub read_integer { Mac::PropertyList::integer->new( $_[0] )  }
sub read_date    { Mac::PropertyList::date   ->new( $_[0] )  }
sub read_real    { Mac::PropertyList::real   ->new( $_[0] )  }
sub read_true    { Mac::PropertyList::true   ->new           }
sub read_false   { Mac::PropertyList::false  ->new           }

=item read_next

Read the next data item

=cut

sub read_next {
	my $source = shift;

	local $_ = '';
	my $value;

	while( not defined $value ) {
		croak "Couldn't read anything!" if $source->eof;
		$_ .= $source->get_line;
		if( s[^\s* < (string|date|real|integer|data) > \s*(.*?)\s* </\1> ][]sx ) {
			$value = $Readers{$1}->( $2 );
			}
		elsif( s[^\s* < string / > ][]x ){
			$value = $Readers{'string'}->( '' );
			}
	    elsif( s[^\s* < (dict|array) > ][]x ) {
			# We need to put back the unprocessed text if
			# any because the <dict> and <array> readers
			# need to see it.
			$source->put_line( $_ ) if defined $_ && '' ne $_;
			$_ = '';
			$value = $Readers{$1}->( $source );
			}
	    # these next two are some wierd cases i found in the iPhoto Prefs
		elsif( s[^\s* < dict / > ][]x ) {
			$value = Mac::PropertyList::dict->new();
			}
	    elsif( s[^\s* < array / > ][]x ) {
			$value = Mac::PropertyList::array->new();
			}
	    elsif( s[^\s* < (true|false) /> ][]x ) {
			$value = $Readers{$1}->();
			}
		}
	$source->put_line($_);
	return $value;
	}

=item read_dict

Read a dictionary

=cut

sub read_dict {
	my $source = shift;

	my %hash;
	local $_ = $source->get_line;
	while( not s|^\s*</dict>|| ) {
		my $key;
		while (not defined $key) {
			if (s[^\s*<key>(.*?)</key>][]s) {
				$key = $1;
				# Bring this back if you want this behavior:
				# croak "Key is empty string!" if $key eq '';
				}
			else {
				croak "Could not read key!" if $source->eof;
				$_ .= $source->get_line;
				}
			}

		$source->put_line( $_ );
		$hash{ $key } = read_next( $source );
		$_ = $source->get_line;
		}

	$source->put_line( $_ );
	if ( 1 == keys %hash && exists $hash{'CF$UID'} ) {
	    # This is how plutil represents a UID in XML.
	    return Mac::PropertyList::uid->integer( $hash{'CF$UID'}->value );
	    }
	else {
	    return Mac::PropertyList::dict->new( \%hash );
	    }
	}

=item read_array

Read an array

=cut

sub read_array {
	my $source = shift;

	my @array = ();

	local $_ = $source->get_line;
	while( not s|^\s*</array>|| ) {
		$source->put_line( $_ );
		push @array, read_next( $source );
		$_ = $source->get_line;
		}

	$source->put_line( $_ );
	return Mac::PropertyList::array->new( \@array );
	}

sub read_data {
	my $string = shift;

	require MIME::Base64;

	$string = MIME::Base64::decode_base64($string);

	return Mac::PropertyList::data->new( $string );
	}

=back

=head2 Things that write

=over 4

=item XML_head

Returns a string that represents the start of the PList XML.

=cut

sub XML_head () {
	<<"XML";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
XML
	}

=item XML_foot

Returns a string that represents the end of the PList XML.

=cut

sub XML_foot () {
	<<"XML";
</plist>
XML
	}

=item plist_as_string

Return the plist data structure as XML in the Mac Property List format.

=cut

sub plist_as_string {
	my $object = CORE::shift;

	my $string = XML_head();

	$string .= $object->write . "\n";

	$string .= XML_foot();

	return $string;
	}

=item plist_as_perl

Return the plist data structure as an unblessed Perl data structure.
There won't be any C<Mac::PropertyList> objects in the results. This
is really just C<as_perl>.

=cut

sub plist_as_perl { $_[0]->as_perl }

=back

=cut

=head1 SOURCE AVAILABILITY

This project is in Github:

	https://github.com/briandfoy/mac-propertylist.git

=head1 CREDITS

Thanks to Chris Nandor for general Mac kung fu and Chad Walker for
help figuring out the recursion for nested structures.

Mike Ciul provided some classes for the different input modes, and
these allow us to optimize the parsing code for each of those.

Ricardo Signes added the C<as_basic_types()> methods so you can dump
all the plist junk and just play with the data.

=head1 TO DO

* change the value of an object

* validate the values of objects (date, integer)

* methods to add to containers (dict, array)

* do this from a filehandle or a scalar reference instead of a scalar
	+ generate closures to handle the work.

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

Tom Wyant added support for UID types.

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=head1 SEE ALSO

http://www.apple.com/DTDs/PropertyList-1.0.dtd

=cut

"See why 1984 won't be like 1984";
