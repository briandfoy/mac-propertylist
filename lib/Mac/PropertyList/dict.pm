package Mac::PropertyList::dict;
use base qw(Mac::PropertyList::Container);

sub new {
	$_[0]->SUPER::new( $_[1] );
	}

sub delete { delete ${ $_[0]->value }{$_[1]}         }
sub exists { exists ${ $_[0]->value }{$_[1]} ? 1 : 0 }
sub count  { scalar CORE::keys %{ $_[0]->value }     }

sub value {
	my $self = shift;
	my $key  = shift;

	do
		{
		if( defined $key ) {
			my $hash = $self->SUPER::value;

			if( exists $hash->{$key} ) { $hash->{$key}->value }
			else                       { return }
			}
		else { $self->SUPER::value }
		};

	}

sub keys   { my @k = CORE::keys %{ $_[0]->value }; wantarray ? @k : \@k; }
sub values {
	my @v = map { $_->value } CORE::values %{ $_[0]->value };
	wantarray ? @v : \@v;
	}

sub as_basic_data {
	my $self = shift;

	my %dict = map {
		my ($k, $v) = ($_, $self->{$_});
		$k => eval { $v->can('as_basic_data') } ? $v->as_basic_data : $v
		} CORE::keys %$self;

	return \%dict;
	}

sub write_key   { "<key>$_[1]</key>" }

sub write {
	my $self  = shift;

	my $string = $self->write_open . "\n";

	foreach my $key ( $self->keys ) {
		my $element = $self->{$key};
		unless( ref $element ) {
			$element = Mac::PropertyList::string->new($string);
			}

		my $bit  = __PACKAGE__->write_key( $key ) . "\n";
		   $bit .= $element->write . "\n";

		$bit =~ s/^/\t/gm;

		$string .= $bit;
		}

	$string .= $self->write_close;

	return $string;
	}

sub as_perl {
	my $self  = CORE::shift;

	my %dict = map {
		my $v = $self->value($_);
		$v = $v->as_perl if eval { $v->can( 'as_perl' ) };
		$_, $v
		} $self->keys;

	return \%dict;
	}

1;
