use strict;
use warnings;

package Mac::PropertyList::Container;
use base qw(Mac::PropertyList::Item);

sub new {
	my( $class, $item ) = @_;

	if( ref $item ) {
		return bless $item, $class;
		}

	my $empty = do {
		   if( $class =~ m/array$/ ) { [] }
		elsif( $class =~ m/dict$/  ) { {} }
		};

	$class->SUPER::new( $empty );
	}

1;
