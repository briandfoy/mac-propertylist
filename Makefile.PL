# $Id$
use ExtUtils::MakeMaker;

sub ExtUtils::MM_Any::test_via_harness 	 
	{ 	 
	my($self, $perl, $tests) = @_; 	 
  	 
    return qq|\t$perl "-MTest::Manifest" | . 	 
		qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | . 	 
		qq|'\$(INST_ARCHLIB)')"\n|; 	 
	}

WriteMakefile
	(
	'NAME'	         => 'Mac::PropertyList',
	'VERSION_FROM'   => 'lib/PropertyList.pm',
	'PREREQ_PM' => { 
		'Test::Manifest'   => '0.9',
		'MIME::Base64'     => '0',
		'Test::More'       => '0',
		},
	'MAN3PODS'		       => {
		'lib/PropertyList.pm'    => '$(INST_MAN3DIR)/Mac::PropertyList.3',
		},
	'PM'        => {
		'lib/PropertyList.pm'     => '$(INST_LIBDIR)/PropertyList.pm',
        },
   
   	clean => { FILES => 'Mac-PropertyList-*' },
   	 
	);

