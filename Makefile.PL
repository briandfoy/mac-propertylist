# $Id$
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile
	(
	'NAME'         => 'Mac::PropertyList',
	'ABSTRACT'     => 'work with Mac plists at a low level',
	'VERSION_FROM' => 'lib/PropertyList.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM' => {
		'MIME::Base64' => '0',
		'Test::More'   => '0',
		},

	'MAN3PODS'		       => {
		'lib/PropertyList.pm'    => '$(INST_MAN3DIR)/Mac::PropertyList.3',
		},

	'PM'                   => {
		'lib/PropertyList.pm'    => '$(INST_LIBDIR)/PropertyList.pm',
		},

	clean                  => { FILES => 'Mac-PropertyList-*' },

	);

