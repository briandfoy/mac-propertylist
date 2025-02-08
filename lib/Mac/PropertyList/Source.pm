use strict;
use warnings;

package Mac::PropertyList::Source;
sub new {
	my $self = bless { buffer => [], source => $_[1] }, $_[0];
	return $self;
	}

sub eof { (not @{$_[0]->{buffer}}) and $_[0]->source_eof }

sub get_line {
	my $self = CORE::shift;

# I'm not particularly happy with what I wrote here, but that's why
# you shouldn't write your own buffering code! I might have left over
# text in the buffer. This could be stuff a higher level looked at and
# put back with put_line. If there's text there, grab that.
#
# But here's the tricky part. If that next part of the text looks like
# a "blank" line, grab the next next thing and append that.
#
# And, if there's nothing in the buffer, ask for more text from
# get_source_line. Follow the same rules. IF you get back something that
# looks like a blank line, ask for another and append it.
#
# This means that a returned line might have come partially from the
# buffer and partially from a fresh read.
#
# At some point you should have something that doesn't look like a
# blank line and the while() will break out. Return what you do.
#
# Previously, I wasn't appending to $_ so newlines were disappearing
# as each next read replaced the value in $_. Yuck.

	local $_ = '';
	while (defined $_ && /^[\r\n\s]*$/) {
		if( @{$self->{buffer}} ) {
			$_ .= shift @{$self->{buffer}};
			}
		else {
			$_ .= $self->get_source_line;
			}
		}

	return $_;
	}

sub put_line { unshift @{$_[0]->{buffer}}, $_[1] }

1;
