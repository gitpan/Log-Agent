#!./perl

#
# $Id: caller.t,v 0.1.1.2 2000/10/01 20:00:24 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: caller.t,v $
# Revision 0.1.1.2  2000/10/01 20:00:24  ram
# patch8: added extra tests for carp
#
# Revision 0.1.1.1  2000/03/05 22:24:29  ram
# patch3: created
#
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
#
# $EndLog$
#

print "1..10\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::File;

unlink 't/file.out', 't/file.err';

my $show_error = __LINE__ + 2;
sub show_error {
	logerr "error string";
}

my $show_output = __LINE__ + 2;
sub show_output {
	logsay "output string";
}

my $show_carp = __LINE__ + 2;
sub show_carp {
	logcarp "carp string";
}

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(
	-driver => $driver,
	-caller => [ -format => "<%s,%.4d>", -info => "sub line", -postfix => 1 ],
);

show_error;
show_output;
my $carp_line = __LINE__ + 1;
show_carp;

my $error_str = sprintf("%.4d", $show_error);
my $output_str = sprintf("%.4d", $show_output);
my $carp_str = sprintf("%.4d", $show_carp);

ok 1, contains("t/file.err", "error string <main::show_error,$error_str>");
ok 2, !contains("t/file.err", "output string");
ok 3, contains("t/file.out", "output string <main::show_output,$output_str>");
ok 4, !contains("t/file.out", "error string");
ok 5, contains("t/file.err",
	"carp string at t/caller.t line $carp_line <main::show_carp,$carp_str>");
ok 6, !contains("t/file.out", "carp string");

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;		# Cheat

$driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(
	-driver => $driver,
	-caller => [ -format => "<%a>", -info => "pack file sub line" ],
);

show_error;
show_output;

$error_str = $show_error;
$output_str = $show_output;
my $file = __FILE__;

ok 7, contains("t/file.err",
	"<main:${file}:main::show_error:$error_str> error");
ok 8, contains("t/file.out",
	"<main:${file}:main::show_output:$output_str> output");

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;		# Cheat

$driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(
	-driver => $driver,
	-caller => [ -display => '<$sub/$line>' ],
);

show_error;
show_output;

ok 9, contains("t/file.err", "<main::show_error\\/$error_str> error");
ok 10, contains("t/file.out", "<main::show_output\\/$output_str> output");

unlink 't/file.out', 't/file.err';

