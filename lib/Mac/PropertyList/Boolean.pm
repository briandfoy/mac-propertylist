use strict;
use warnings;

package Mac::PropertyList::Boolean;
use base qw(Mac::PropertyList::Item);

sub new {
	my $class = shift;

	my( $type ) = $class =~ m/.*::(.*)/g;

	$class->either( $type );
	}

sub either { my $copy = $_[1]; bless \$copy, $_[0]  }

sub write  { $_[0]->write_empty }

1;
