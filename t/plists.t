# $Id$
BEGIN {
	use File::Find::Rule;
	@plists = File::Find::Rule->file()->name( '*.plist' )->in( 'plists' );
	}

use Test::Builder;
use Test::More tests => scalar @plists;
use Time::HiRes qw(tv_interval gettimeofday);

use Mac::PropertyList;

my $debug = $ENV{PLIST_DEBUG} || 0;

foreach my $file ( @plists )
	{
	diag( "Working on $file" ) if $debug;
	unless( open FILE, $file )
		{
		fail( "Could not open $file" );
		}
		
	my $data = do { local $/; <FILE> };
	close FILE;

	my $b = length $data;

	my $time1 = [ gettimeofday ];
	my $plist = Mac::PropertyList::parse_plist( $data );
	my $time2 = [ gettimeofday ];

	my $elapsed = tv_interval( $time1, $time2 );
	diag( "$file [$b bytes] parsed in $elapsed seconds" );

	isa_ok( $plist, 'HASH' );
	}
