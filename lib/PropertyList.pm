# $Id$
package Mac::PropertyList;
use strict;

use vars qw($ERROR);

=head1 NAME

Mac::PropertyList - work with Mac plists

=head1 SYNOPSIS

	use Mac::PropertyList;
	
	my $data = parse_plist( $text );

	my $text = plist_as_string( $data );
	
=head1 DESCRIPTION

=head2 The plist format

=head2 The Mac::PropertyList data structure

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

=cut

sub plist_as_string
	{
	my $ref = shift;
	
	my $string = '';
	
	return $string;
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
		my $bit .= $Writers{$type}->( $value ) . "\n";
		
		$bit =~ s/$/\t/gm;
		
		$string .= $bit;
		}
	
	$string .= "</dict>\n";
	
	return $string;		
	}

=back

=head1 TO DO

=head1 BUGS

=head1 AUTHOR

brian d foy, E<lt>brian d foyE<gt>

=head1 SEE ALSO

=cut

"See why 1984 won't be like 1984";
