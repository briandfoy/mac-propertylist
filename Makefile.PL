# $Id$
use ExtUtils::MakeMaker;

use Test::Manifest qw(get_t_files);

WriteMakefile
	(
    'NAME'	    => 'Mac::PropertyList',
    'VERSION'   => '0.04',
	'PREREQ_PM' => { 
		'Test::Manifest' => undef,
		'Test::More'     => undef,
		'Test::Pod'      => undef,
		'Text::Balanced' => undef 
		},
    'PM'        => {
        'lib/PropertyList.pm'     => '$(INST_LIBDIR)/PropertyList.pm',
        },
    
    depend => { Makefile => "t/test_manifest" },
    test   => { TESTS => scalar get_t_files() },
	);

