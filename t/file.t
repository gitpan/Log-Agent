#!./perl

#
# $Id: file.t,v 0.1 1999/12/07 21:09:45 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: file.t,v $
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
#
# $EndLog$
#

print "1..26\n";

require 't/code.pl';

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

print "not " unless contains("t/file.err", '\d Error$');
print "ok 1\n";
print "not " if contains("t/file.out", 'Error');
print "ok 2\n";
print "not " unless contains("t/file.err", '\d Message$');
print "ok 3\n";
print "not " if contains("t/file.out", 'Message');
print "ok 4\n";

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

print "not " unless $@;
print "ok 5\n";

print "not " unless contains("t/file.err", '^DATE me\[\d+\]: error$');
print "ok 6\n";
print "not " unless contains("t/file.out", 'ERROR: error');
print "ok 7\n";
print "not " unless contains("t/file.out", '^DATE me\[\d+\]: message$');
print "ok 8\n";
print "not " if contains("t/file.err", 'message');
print "ok 9\n";
print "not " unless contains("t/file.err", '^DATE me\[\d+\]: warning$');
print "ok 10\n";
print "not " unless contains("t/file.out", 'WARNING: warning');
print "ok 11\n";
print "not " unless contains("t/file.err", '^DATE me\[\d+\]: die$');
print "ok 12\n";
print "not " unless contains("t/file.out", 'FATAL: die');
print "ok 13\n";

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

print "not " unless $@;
print "ok 14\n";

print "not " unless contains("t/file.err", '^DATE me: error$');
print "ok 15\n";
print "not " if contains("t/file.out", 'error');
print "ok 16\n";
print "not " unless contains("t/file.out", '^DATE me: message$');
print "ok 17\n";
print "not " if contains("t/file.err", 'message');
print "ok 18\n";
print "not " unless contains("t/file.err", '^DATE me: warning$');
print "ok 19\n";
print "not " if contains("t/file.out", 'warning');
print "ok 20\n";
print "not " unless contains("t/file.err", '^DATE me: die$');
print "ok 21\n";
print "not " if contains("t/file.out", 'die');
print "ok 22\n";

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

print "not " if -e '>&main::FILE';
print "ok 23\n";
print "not " unless -e 't/file.err';
print "ok 24\n";
print "not " unless contains("t/file.err", 'me: error$');
print "ok 25\n";
print "not " unless contains("t/file.err", 'me: should go to');
print "ok 26\n";

unlink 't/file.err';
