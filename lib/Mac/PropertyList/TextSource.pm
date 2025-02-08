use strict;
use warnings;

package Mac::PropertyList::TextSource;
use base qw(Mac::PropertyList::Source);

sub get_source_line {
	my $self = CORE::shift;
	$self->{source} =~ s/(.*(\r|\n|$))//;
	$1;
	}

sub source_eof { not $_[0]->{source} }

1;
