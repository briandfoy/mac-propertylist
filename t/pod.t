# $Id$

BEGIN {
	use File::Find::Rule;
	@files = File::Find::Rule->file()->name( '*.pm' )->in( 'blib/lib' );
	}
	
use Test::Pod tests => scalar @files;

foreach my $file ( @files )
	{
	pod_ok($file);
	}
