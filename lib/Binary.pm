package Mac::PropertyList::Binary;
use strict;
use warnings;

use Carp;
use Data::Dumper;
use Math::BigInt;

__PACKAGE__->run( @ARGV ) unless caller;

sub run
	{
	my $parsed = $_[0]->new( $_[1] );
	
	print Dumper( $parser );
	}
	
sub new {
	my( $class, $file ) = @_;
	
	bless { file => $file }, $class;
	
	$self->_read;
	
	$self;
	}

sub _file    { $_[0]->{file} }
sub _fh      { $_[0]->{fh}  }
sub _trailer { $_[0]->{trailer} }
sub _offsets { $_[0]->{offsets} }

sub _read {
	my $self = shift;

	open my( $input ), "<", $self->_file or croak "Could not open file! $!";

	$self->_read_plist_trailer( $input );
	print Dumper( $self );
	
	$self->_get_offset_table( $input, $trailer->{table_offest};
	
# get the offset table
    seek(INF, $OffsetTableOffset, SEEK_SET);
    my $rawOffsetTable;
    my $readSize = read(INF, $rawOffsetTable, $NumObjects * $OffsetSize);
    if ($readSize != $NumObjects * $OffsetSize) {
      die "rawOffsetTable read $readSize expected ",$NumObjects * $OffsetSize;
    }

    @Offsets = unpack(["","C*","n*","(H6)*","N*"]->[$OffsetSize], $rawOffsetTable);
    if ($OffsetSize == 3) {
	@Offsets = map { hex($_) } @Offsets;
    }

    $ILen = 0;
    $MLen = 0;
    $SLen = 0;

    my $top = $self->_read_object_at_offset($TopObject);

}

sub _read_plist_trailer
	{
	my $self = shift;
	
	seek $fh, -32, SEEK_END;

	my $buffer;
	read $fh, $buffer, 32;
	my %hash;
	
	@hash{ qw( offset_size ref_size object_count top_object table_offset ) }
		= unpack "x6 C C (x4 N)3", $buffer;

	$self->{trailer} = \%hash;
	}	
	
sub _get_offset_table
	{
	my $self = shift;
	
    seek $fh, $self->_trailer->{table_offset}, SEEK_SET;

	my $try_to_read = $self->_trailer->{object_count} * $self->_trailer->{offset_size};

    my $raw_offset_table;
    my $read = read $fh, $raw_offset_table, $try_to_read;
    
	croak "reading offset table failed!" unless $read == $try_to_read;

    my @offsets = unpack ["","C*","n*","(H6)*","N*"]->[$self->_trailer->{offset_size}], $raw_offset_table;

	$self->{offsets} = \@offsets;
	
    if( $self->_trailer->{offset_size} == 3 ) 
    	{
		@offsets = map { hex } @offsets;
   	 	}
	
	}

sub _read_object 
	{
	my $self = shift;

    my $buffer;
    croak "Didn't get type byte at offset $offset" 
    	unless read( $self->_fh, $buffer, 1) == 1;

    my $length = unpack( "C*", $buffer ) & 0x0F;

    $buffer    = unpack "H*", $buffer;
    my $type   = substr $buffer, 0, 1;
    
	$objLen = ReadBObject()->[1] if( $type ne "0" && $length == 15 );

	my $sub = $type_readers{ $type };
	my $result = eval { $sub->( $length ) };
	croak "" if $@;

    return $answer;
	}

sub _read_object_at_offset {
	my( $self, $offset ) = @_;

    seek $self->_fh, ${ $self->_offsets }[$offset], SEEK_SET;
    
    $self->_read_object;
	}

# # # # # # # # # # # # # #

my $type_readers = {

	0 => sub {
		my( $self, $length ) = @_;

		$self->{MLen}++;
		
		my $hash = (
			 0 => [ qw(null  0) ],
			 8 => [ qw(false 0) ],
			 9 => [ qw(true  1) ],
			15 => [ qw(fill 15) ],
			)
	
		return $hash{ $length } || [];
    	},

	1 => sub { # integers
		my( $self, $length ) = @_;
		croak "Integer > 8 bytes = $length" if $length > 3;

		my $byte_length = 1 << $length;

		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( C n N NN );
		my @values = unpack $format[$length], $buffer;
		
		if( $length == 3 )
			{
			my( $high, $low ) = @values;
			
			my $b = Math::BigInt->new($high)->blsft(32)->bior($low);
			if( $b->bcmp(Math::BigInt->new(2)->bpow(63)) > 0) {
				$b -= Math::BigInt->new(2)->bpow(64);
				}
				
			@values = ( $b );
			}

		$self->{ILen} += $byte_length + 1;
	
		return [ "integer", $values[0] ];
		},

	2 => sub { # reals
		my( $self, $length ) = @_;
		croak "Real > 8 bytes" if $length > 3;
		croak "Bad length [$length]" if $length < 2;
		
		my $byte_length = 1 << $length;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( a a f d );
		my @values = unpack $format[$length], $buffer;

		$self->{MLen} += 9;
	
		return [ "real", $values[0] ];
		},

	3 => sub { # date
		my( $self, $length ) = @_;
		croak "Real > 8 bytes" if $length > 3;
		croak "Bad length [$length]" if $length < 2;
	
		my $byte_length = 1 << $length;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $byte_length;

		my @formats = qw( a a f d );
		my @values = unpack $format[$length], $buffer;

		$self->{MLen} += 9;	

		return [ "date", $values[0] ];
		},

	4 => sub { # binary data
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $length;
	
		$self->{MLen} += $length + 1;
	
		return ["data", $buf];
		},


	5 => sub { # utf8 string
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, $length;
	
		unless( defined $RStrings{$buffer} ) 
			{
			$self->{SLen} += $length + 1;
			$RStrings{$buffer} = 1;
			}
		else 
			{
			$self->{ILen} -= CountIntSize($length);
			}
	
		# pack to make it unicode
		$buffer = pack "U0C*", unpack "C*", $buffer;
	
		return [ "string", $buffer ];
		},

	6 => sub { # unicode string
		my( $self, $length ) = @_;
	
		my( $buffer, $value );
		read $self->_fh, $buffer, 2 * $length;
	
		unless( defined $RStrings{$buffer} ) 
			{
			$self->{SLen} += 2 * $length + 1;
			$RStrings{$buffer} = 1;
			}
		else 
			{
			$self->{ILen} -= CountIntSize($length);
			}
	
		$buffer = decode( "UTF-16BE", $buffer );
		
		return [ "ustring", $buffer ];
		},

	a => sub { # array
		my( $self, $elements ) = @_;
	
		my @array;
	
		# get the references
		my $buffer;
		read $self->_inf, $buffer, $length * $self->_object_ref_size;
		my @objects = unpack( 
			($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
			);
	
		my @array = 
			map { $self->ReadBObjectAt( $objects[$_] ) } 
			0 .. $elements - 1; 
	
		$self->{MLen}++;
	
		return [ "array", \@array ];
		}

	d => sub { # dictionary
		my( $self, $length ) = @_;
	
		my @keys = do {
			my $buffer;
			read $self->_fh, $buffer, $length * $self->_object_ref_size;
			unpack( 
				($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
				);
			};
	
		my @objects = do {
			my $buffer;
			read $self->_fh, $buffer, $objLen * $self->_object_ref_size;
			unpack(
				($self->_object_ref_size == 1 ? "C*" : "n*"), $buffer 
				);
			};

		my %dict = map {
			my $key = $self->_read_object_at_offset($keys[$_])->[1];
			my $obj = $self->_read_object_at_offset($objects[$j]);
			( $key, $obj );
			} 0 .. $length - 1;
	
		$self->{MLen}++;
	
		return [ "dict", \%dict ];
		}
	};
