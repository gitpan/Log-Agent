#!./perl

#
# $Id: default.t,v 0.1 1999/12/07 21:09:45 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: default.t,v $
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
#
# $EndLog$
#

print "1..17\n";

require 't/code.pl';

use Log::Agent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/default.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/default.err") || die "can't redirect STDERR: $!\n";

logerr "error";
logsay "message";

close STDOUT;
close STDERR;

print "not " unless contains("t/default.err", '^Error$');
print "ok 1\n";
print "not " if contains("t/default.out", '^Error$');
print "ok 2\n";
print "not " unless contains("t/default.out", '^Message$');
print "ok 3\n";
print "not " if contains("t/default.err", '^Message$');
print "ok 4\n";

open(STDOUT, ">t/default.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/default.err") || die "can't redirect STDERR: $!\n";

undef $Log::Agent::Driver;		# Cheat
logconfig(-prefix => 'me', -trace => 6, -debug => 8);

logtrc 'notice', "notice";
logtrc 'info', "trace-info";
logdbg 'info', "debug-info";
logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };
print STDERR $@;				# We trapped it

print "not " unless $@;
print "ok 5\n";

close STDOUT;
close STDERR;

print "not " unless contains("t/default.err", '^me: error$');
print "ok 6\n";
print "not " if contains("t/default.out", 'error');
print "ok 7\n";
print "not " unless contains("t/default.out", '^me: message$');
print "ok 8\n";
print "not " if contains("t/default.err", 'message');
print "ok 9\n";
print "not " unless contains("t/default.err", '^me: WARNING: warning$');
print "ok 10\n";
print "not " if contains("t/default.out", 'warning');
print "ok 11\n";
print "not " unless contains("t/default.err", '^me: die$');
print "ok 12\n";
print "not " if contains("t/default.out", 'die');
print "ok 13\n";
print "not " if contains("t/default.err", 'notice|info');
print "ok 14\n";
print "not " unless contains("t/default.out", '^me: notice$');
print "ok 15\n";
print "not " unless contains("t/default.out", '^me: debug-info$');
print "ok 16\n";
print "not " if contains("t/default.out", '^me: trace-info$');
print "ok 17\n";

unlink 't/default.out', 't/default.err';

