package Mac::PropertyList::Binary;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Mac::PropertyList;
use Math::BigInt;
use POSIX qw(SEEK_END SEEK_SET);

my %RStrings;

__PACKAGE__->run( @ARGV ) unless caller;

sub run
	{
	my $parser = $_[0]->new( $_[1] );
	
	print Dumper( $parser->parsed );
	}
	
sub new {
	my( $class, $file ) = @_;
	
	my $self = bless { file => $file }, $class;
	
	$self->_read;
	
	$self;
	}

sub _file            { $_[0]->{file}               }
sub _fh              { $_[0]->{fh}                 }
sub _trailer         { $_[0]->{trailer}            }
sub _offsets         { $_[0]->{offsets}            }
sub _object_ref_size { $_[0]->_trailer->{ref_size} }
sub parsed           { $_[0]->{parsed}             }

sub _object_size 
	{   
	$_[0]->_trailer->{object_count} * $_[0]->_trailer->{offset_size} 
	}

sub _read
	{
	my $self = shift;

	open my( $input ), "<", $self->_file or croak "Could not open file! $!";
	$self->{fh} = $input;
	$self->_read_plist_trailer( $input );
	print Dumper( $self );
	
	$self->_get_offset_table;
	
    my $top = $self->_read_object_at_offset( $self->_trailer->{top_object} );
    
    $self->{parsed} = $top;
	}

sub _read_plist_trailer
	{
	my $self = shift;
	
	seek $self->_fh, -32, SEEK_END;

	my $buffer;
	read $self->_fh, $buffer, 32;
	my %hash;
	
	@hash{ qw( offset_size ref_size object_count top_object table_offset ) }
		= unpack "x6 C C (x4 N)3", $buffer;

	$self->{trailer} = \%hash;
	}	
	
sub _get_offset_table
	{
	my $self = shift;
	
    seek $self->_fh, $self->_trailer->{table_offset}, SEEK_SET;

	my $try_to_read = $self->_object_size;

    my $raw_offset_table;
    my $read = read $self->_fh, $raw_offset_table, $try_to_read;
    
	croak "reading offset table failed!" unless $read == $try_to_read;

    my @offsets = unpack ["","C*","n*","(H6)*","N*"]->[$self->_trailer->{offset_size}], $raw_offset_table;

	$self->{offsets} = \@offsets;
	
    if( $self->_trailer->{offset_size} == 3 ) 
    	{
		@offsets = map { hex } @offsets;
   	 	}
	
	}

sub _read_object_at_offset {
	my( $self, $offset ) = @_;

	my @caller = caller(1);
	
    seek $self->_fh, ${ $self->_offsets }[$offset], SEEK_SET;
    
    $self->_read_object;
	}

# # # # # # # # # # # # # #

BEGIN {
my $type_readers = {

	0 => sub { # the odd balls
		my( $self, $length ) = @_;
		
		my %hash = (
			 0 => [ qw(null  0) ],
			 8 => [ qw(false 0) ],
			 9 => [ qw(true  1) ],
			15 => [ qw(fill 15) ],
			);
	
		return $hash{ $length } || [];
    	},

	1 => sub { # integers
		my( $self, $length ) = @_;
		croak "Integer > 8 bytes = $length" if $length > 3;

		my $byte_length = 1 << $length;

		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( C n N NN );
		my @values = unpack $formats[$length], $buffer;
		
		if( $length == 3 )
			{
			my( $high, $low ) = @values;
			
			my $b = Math::BigInt->new($high)->blsft(32)->bior($low);
			if( $b->bcmp(Math::BigInt->new(2)->bpow(63)) > 0) 
				{
				$b -= Math::BigInt->new(2)->bpow(64);
				}
				
			@values = ( $b );
			}
	
		return Mac::PropertyList::integer->new( $values[0] );
		},

	2 => sub { # reals
		my( $self, $length ) = @_;
		croak "Real > 8 bytes" if $length > 3;
		croak "Bad length [$length]" if $length < 2;
		
		my $byte_length = 1 << $length;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( a a f d );
		my @values = unpack $formats[$length], $buffer;
	
		return Mac::PropertyList::real->new( $values[0] );
		},

	3 => sub { # date
		my( $self, $length ) = @_;
		croak "Real > 8 bytes" if $length > 3;
		croak "Bad length [$length]" if $length < 2;
	
		my $byte_length = 1 << $length;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( a a f d );
		my @values = unpack $formats[$length], $buffer;

		$self->{MLen} += 9;	

		return Mac::PropertyList::date->new( $values[0] );
		},

	4 => sub { # binary data
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $length;
		
		return Mac::PropertyList::data->new( $buffer );
		},


	5 => sub { # utf8 string
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $length;
		
		# pack to make it unicode
		$buffer = pack "U0C*", unpack "C*", $buffer;
	
		return Mac::PropertyList::string->new( $buffer );
		},

	6 => sub { # unicode string
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, 2 * $length;
		
		$buffer = decode( "UTF-16BE", $buffer );
		
		return Mac::PropertyList::ustring->new( $buffer );
		},

	a => sub { # array
		my( $self, $elements ) = @_;
		
		my @objects = do {
			my $buffer;
			read $self->_fh, $buffer, $elements * $self->_object_ref_size;
			unpack( 
				($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
				);
			};
	
		my @array = 
			map { $self->_read_object_at_offset( $objects[$_] ) } 
			0 .. $elements - 1; 
	
		return Mac::PropertyList::array->new( \@array );
		},

	d => sub { # dictionary
		my( $self, $length ) = @_;
		
		my @key_indices = do {
			my $buffer;
			my $s = $self->_object_ref_size;
			read $self->_fh, $buffer, $length * $self->_object_ref_size;
			unpack( 
				($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
				);
			};
		
		my @objects = do {
			my $buffer;
			read $self->_fh, $buffer, $length * $self->_object_ref_size;
			unpack(
				($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
				);
			};

		my %dict = map {
			my $key   = $self->_read_object_at_offset($key_indices[$_])->value;
			my $value = $self->_read_object_at_offset($objects[$_]);
			( $key, $value );
			} 0 .. $length - 1;
		
		return Mac::PropertyList::dict->new( \%dict );
		},
	};

sub _read_object 
	{
	my $self = shift;

    my $buffer;
    croak "read() failed while trying to get type byte! $!" 
    	unless read( $self->_fh, $buffer, 1) == 1;

    my $length = unpack( "C*", $buffer ) & 0x0F;
    
    $buffer    = unpack "H*", $buffer;
    my $type   = substr $buffer, 0, 1;    
    
	$length = $self->_read_object->value if $type ne "0" && $length == 15;

	my $sub = $type_readers->{ $type };
	my $result = eval { $sub->( $self, $length ) };
	croak "$@" if $@;	

    return $result;
	}
	
}
