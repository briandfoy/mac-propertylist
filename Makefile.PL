# $Id$
use ExtUtils::MakeMaker;

my $tests = do {
	local @ARGV = qw(t/test_manifest);
	my $data = join " ", map {chomp; "t/$_" } <>;
	};
	
WriteMakefile
	(
    'NAME'	    => 'Mac::PropertyList',
    'VERSION'   => '0.06',
	'PREREQ_PM' => { 
		File::Find::Rule => 0,
		Test::More       => 0,
		Test::Pod        => 0,
		Time::HiRes      => 0,
		},
    'PM'        => {
        'lib/PropertyList.pm'     => '$(INST_LIBDIR)/PropertyList.pm',
        },
    
    depend => { Makefile => "t/test_manifest" },
    test   => { TESTS => $tests },
	);

