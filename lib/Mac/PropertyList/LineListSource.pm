use strict;
use warnings;

package Mac::PropertyList::LineListSource;
use base qw(Mac::PropertyList::Source);

sub get_source_line { return shift @{$_->{source}} if @{$_->{source}} }

sub source_eof { not @{$_[0]->{source}} }

1;
