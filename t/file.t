#!./perl

#
# $Id: file.t,v 0.2 2000/11/06 19:30:34 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: file.t,v $
# Revision 0.2  2000/11/06 19:30:34  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..26\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::File;

my $driver = Log::Agent::Driver::File->make();		# take all defaults
logconfig(-driver => $driver);

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/file.err") || die "can't redirect STDERR: $!\n";

logerr "error";
logsay "message";

close STDOUT;
close STDERR;

ok 1, contains("t/file.err", '\d Error$');
ok 2, !contains("t/file.out", 'Error');
ok 3, contains("t/file.err", '\d Message$');
ok 4, !contains("t/file.out", 'Message');

undef $Log::Agent::Driver;		# Cheat

$driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-showpid => 1,
	-stampfmt => sub { 'DATE' },
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
	-duperr => 1,
);
logconfig(-driver => $driver);

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

ok 5, $@;

ok 6, contains("t/file.err", '^DATE me\[\d+\]: error$');
ok 7, contains("t/file.out", 'ERROR: error');
ok 8, contains("t/file.out", '^DATE me\[\d+\]: message$');
ok 9, !contains("t/file.err", 'message');
ok 10, contains("t/file.err", '^DATE me\[\d+\]: warning$');
ok 11, contains("t/file.out", 'WARNING: warning');
ok 12, contains("t/file.err", '^DATE me\[\d+\]: die$');
ok 13, contains("t/file.out", 'FATAL: die');

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;		# Cheat

$driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-stampfmt => sub { 'DATE' },
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(-driver => $driver);

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

ok 14, $@;

ok 15, contains("t/file.err", '^DATE me: error$');
ok 16, !contains("t/file.out", 'error');
ok 17, contains("t/file.out", '^DATE me: message$');
ok 18, !contains("t/file.err", 'message');
ok 19, contains("t/file.err", '^DATE me: warning$');
ok 20, !contains("t/file.out", 'warning');
ok 21, contains("t/file.err", '^DATE me: die$');
ok 22, !contains("t/file.out", 'die');

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;		# Cheat
open(FILE, '>t/file.err');

$driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-magic_open => 1,
	-channels => {
		'error' => '>&main::FILE',
	},
);
logconfig(-driver => $driver);

logerr "error";
logsay "should go to error";

close FILE;

ok 23, !-e '>&main::FILE';
ok 24, -e 't/file.err';
ok 25, contains("t/file.err", 'me: error$');
ok 26, contains("t/file.err", 'me: should go to');

unlink 't/file.err';

