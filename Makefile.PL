# $Id$
use ExtUtils::MakeMaker;

WriteMakefile
	(
    'NAME'	    => 'Mac::PropertyList',
    'VERSION'   => '0.01',
	'PREREQ_PM' => { 'Text::Balanced' => undef },
     'PM'       => {
        'lib/PropertyList.pm'     => '$(INST_LIBDIR)/PropertyList.pm',
         },
	);

