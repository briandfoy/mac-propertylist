use strict;
use warnings;

package Mac::PropertyList::Scalar;
use base qw(Mac::PropertyList::Item);

sub new { my $copy = $_[1]; $_[0]->SUPER::new( \$copy ) }

sub as_basic_data { $_[0]->value }

sub write { $_[0]->write_open . $_[0]->value . $_[0]->write_close }

sub as_perl { $_[0]->value }

1;
