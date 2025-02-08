use strict;
use warnings;

package Mac::PropertyList::Item;
sub type_value { ( $_[0]->type, $_[0]->value ) }

sub value {
	my $ref = $_[0]->type;

	do {
		   if( $ref eq 'array' ) { wantarray ? @{ $_[0] } : $_[0] }
		elsif( $ref eq 'dict'  ) { wantarray ? %{ $_[0] } : $_[0] }
		else                     { ${ $_[0] } }
		};
	}

sub type { my $r = ref $_[0] ? ref $_[0] : $_[0]; $r =~ s/.*:://; $r; }

sub new {
	bless $_[1], $_[0]
	}

sub write_open  { $_[0]->write_either(); }
sub write_close { $_[0]->write_either('/'); }

sub write_either {
	my $slash = defined $_[1] ? '/' : '';

	my $type = $_[0]->type;

	"<$slash$type>";
	}

sub write_empty { my $type = $_[0]->type; "<$type/>"; }

1;
