use strict;
use warnings;

package Mac::PropertyList::uid;
use base qw(Mac::PropertyList::Scalar);

# The following is conservative, since the actual largest unsigned
# integer is ~0, which is 0xFFFFFFFFFFFFFFFF on many (most?) modern
# Perls; but it is consistent with Mac::PropertyList::ReadBinary.
# This is really just future-proofing though, since it appears from
# CFBinaryPList.c that a UID is carried as a hard-coded uint32_t.
use constant LONGEST_HEX_REPRESENTABLE_AS_NATIVE => 8;	# 4 bytes

# Instantiate with hex string. The string will be padded on the left
# with zero if its length is odd. It is this string which will be
# returned by value(). Presence of a non-hex character causes an
# exception. We default the argument to '00'.
sub new {
	my ( $class, $value ) = @_;
	$value = '00' unless defined $value;
	Carp::croak( 'uid->new() argument must be hexadecimal' )
		if $value =~ m/ [[:^xdigit:]] /smx;
	substr $value, 0, 0, '0'
		if length( $value ) % 2;
	return $class->SUPER::new( $value );
	}

# Without argument, this is an accessor returning the value as an unsigned
# integer, either a native Perl value or a Math::BigInt as needed.
# With argument, this is a mutator setting the value to the hex
# representation of the argument, which must be an unsigned integer,
# either native Perl of Math::BigInt object. If called as static method
# instantiates a new object.
sub integer {
	my ( $self, $integer ) = @_;
	if ( @_ < 2 ) {
		my $value = $self->value();
		return length( $value ) > LONGEST_HEX_REPRESENTABLE_AS_NATIVE ?
			Math::BigInt->from_hex( $value ) :
			hex $value;
		}
	else {
		Carp::croak( 'uid->integer() argument must be unsigned' )
			if $integer < 0;
		my $value = ref $integer ?
			$integer->to_hex() :
			sprintf '%x', $integer;
		if ( ref $self ) {
			substr $value, 0, 0, '0'
				if length( $value ) % 2;
			${ $self } = $value;
			}
		else {
			$self = $self->new( $value );
			}
		return $self;
		}
	}

# This is how plutil represents a UID in XML.
sub write {
	my $self = shift;
	my $dict = Mac::PropertyList::dict->new( {
			'CF$UID' => Mac::PropertyList::integer->new(
				$self->integer ),
			}
		);
	return $dict->write();
	}

1;
