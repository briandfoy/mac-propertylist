# $Id$
use ExtUtils::MakeMaker;

my @Tests = map { "t/$_" } qw(
load.t
parse.t
);

WriteMakefile
	(
    'NAME'	    => 'Mac::PropertyList',
    'VERSION'   => '0.02',
	'PREREQ_PM' => { 'Text::Balanced' => undef },
     'PM'       => {
        'lib/PropertyList.pm'     => '$(INST_LIBDIR)/PropertyList.pm',
         },
     test => { TESTS => join( " ", @Tests ) },
	);

