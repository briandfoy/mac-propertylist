use strict;
use warnings;

package Mac::PropertyList::array;
use base qw(Mac::PropertyList::Container);

sub shift   { CORE::shift @{ $_[0]->value } }
sub unshift { }
sub pop     { CORE::pop @{ $_[0]->value }   }
sub push    { }
sub splice  { }
sub count   { return scalar @{ $_[0]->value } }
sub _elements { @{ $_[0]->value } } # the raw, unprocessed elements
sub values {
	my @v = map { $_->value } $_[0]->_elements;
	wantarray ? @v : \@v
	}

sub as_basic_data {
	my $self = CORE::shift;
	return
		[ map
		{
		eval { $_->can('as_basic_data') } ? $_->as_basic_data : $_
		} @$self
		];
	}

sub write {
	my $self  = CORE::shift;

	my $string = $self->write_open . "\n";

	foreach my $element ( @$self ) {
		my $bit = $element->write;

		$bit =~ s/^/\t/gm;

		$string .= $bit . "\n";
		}

	$string .= $self->write_close;

	return $string;
	}

sub as_perl {
	my $self  = CORE::shift;

	my @array = map { $_->as_perl } $self->_elements;

	return \@array;
	}

1;
