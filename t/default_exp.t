#!./perl

#
# $Id: default_exp.t,v 0.1.1.1 2000/03/05 22:24:59 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: default_exp.t,v $
# Revision 0.1.1.1  2000/03/05 22:24:59  ram
# patch3: created
#
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
#
# $EndLog$
#

#
# This is the continuation of t/default.t.
# It was split to circumvent a Perl 5.005 or glibc bug on Linux platforms.
#

print "1..13\n";

require 't/code.pl';
sub ok;

use Log::Agent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/default.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/default.err") || die "can't redirect STDERR: $!\n";

logconfig(-prefix => 'me', -trace => 6, -debug => 8);

logtrc 'notice', "notice";
logtrc 'info', "trace-info";
logdbg 'info', "debug-info";
logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };
print STDERR $@;				# We trapped it

ok 1, $@;

close STDOUT;
close STDERR;

ok 2, contains("t/default.err", '^me: error$');
ok 3, !contains("t/default.out", 'error');
ok 4, contains("t/default.out", '^me: message$');
ok 5, !contains("t/default.err", 'message');
ok 6, contains("t/default.err", '^me: WARNING: warning$');
ok 7, !contains("t/default.out", 'warning');
ok 8, contains("t/default.err", '^me: die$');
ok 9, !contains("t/default.out", 'die');
ok 10, !contains("t/default.err", 'notice|info');
ok 11, contains("t/default.out", '^me: notice$');
ok 12, contains("t/default.out", '^me: debug-info$');
ok 13, !contains("t/default.out", '^me: trace-info$');

unlink 't/default.out', 't/default.err';

