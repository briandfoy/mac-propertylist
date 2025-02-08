#!perl
use strict;
use warnings;

use Test::More;

my $class = 'Mac::PropertyList';
my @shortcuts = map { "pl_$_" } qw(
	dict array
	true false
	data date integer real uid
	);

subtest 'sanity' => sub {
	use_ok $class;
	can_ok $class, @shortcuts;
	};

subtest 'import' => sub {
	subtest 'pre-import' => sub {
		foreach my $shortcut ( @shortcuts ) {
			no strict 'refs';
			ok ! defined &{$shortcut}, "$shortcut is not yet imported";
			}
		};

	$class->import(':shortcuts');

	subtest 'post-import' => sub {
		foreach my $shortcut ( @shortcuts ) {
			no strict 'refs';
			ok defined &{$shortcut}, "$shortcut was imported";
			}
		};
	};

subtest 'nullary' => sub {
	subtest 'false' => sub {
		isa_ok pl_false(), 'Mac::PropertyList::false';
		my $rc = eval { pl_false('foo') };
		is $rc, undef, 'more than zero arguments croaks';
		like $@, qr/Too many/, 'croak message matches';
		};
	subtest 'true' => sub {
		isa_ok pl_true(), 'Mac::PropertyList::true';
		my $rc = eval { pl_true('foo') };
		is $rc, undef, 'more than zero arguments croaks';
		like $@, qr/Too many/, 'croak message matches';
		};
	};

subtest 'unary' => sub {
	subtest 'data' => sub {
		isa_ok pl_data(137), 'Mac::PropertyList::data';
		subtest 'too few' => sub {
			my $rc = eval { pl_data() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_data(1,2) };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};

	subtest 'date' => sub {
		isa_ok pl_date(137), 'Mac::PropertyList::date';
		subtest 'too few' => sub {
			my $rc = eval { pl_date() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_date(1,2) };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};

	subtest 'integer' => sub {
		isa_ok pl_integer(137), 'Mac::PropertyList::integer';
		subtest 'too few' => sub {
			my $rc = eval { pl_integer() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_integer(1,2) };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};

	subtest 'real' => sub {
		isa_ok pl_real(137), 'Mac::PropertyList::real';
		subtest 'too few' => sub {
			my $rc = eval { pl_real() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_real(1,2) };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};

	subtest 'string' => sub {
		isa_ok pl_string("Hello"), 'Mac::PropertyList::string';
		subtest 'too few' => sub {
			my $rc = eval { pl_string() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_string("Hello", "Goodbye") };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};

	subtest 'uid' => sub {
		isa_ok pl_uid("abcd"), 'Mac::PropertyList::uid';
		subtest 'too few' => sub {
			my $rc = eval { pl_uid() };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Not enough/, 'croak message matches';
			};
		subtest 'too many' => sub {
			my $rc = eval { pl_uid("Hello", "Goodbye") };
			is $rc, undef, 'more than zero arguments croaks';
			like $@, qr/Too many/, 'croak message matches';
			};
		};
	};

subtest 'collections' => sub {
	subtest 'array' => sub {
		isa_ok pl_array(), 'Mac::PropertyList::array';
		isa_ok pl_array( pl_integer(137) ), 'Mac::PropertyList::array';
		isa_ok pl_array( pl_integer(137), pl_string("Hello") ), 'Mac::PropertyList::array';
		};

	subtest 'hash' => sub {
		isa_ok pl_dict(), 'Mac::PropertyList::dict';
		isa_ok pl_dict( number => pl_integer(137) ), 'Mac::PropertyList::dict';

		};
	};


done_testing();
