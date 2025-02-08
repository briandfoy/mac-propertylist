use strict;
use warnings;

package Mac::PropertyList::data;
use base qw(Mac::PropertyList::Scalar);

sub write {
	my $self  = shift;

	my $type  = $self->type;
	my $value = $self->value;

	require MIME::Base64;

	my $string = MIME::Base64::encode_base64($value);

	$self->write_open . $string . $self->write_close;
	}

1;
