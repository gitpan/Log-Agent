#!./perl

#
# $Id: default_exp.t,v 0.2 2000/11/06 19:30:34 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: default_exp.t,v $
# Revision 0.2  2000/11/06 19:30:34  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

#
# This is the continuation of t/default.t.
# It was split to circumvent a Perl 5.005 or glibc bug on Linux platforms.
#

print "1..8\n";

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
ok 3, contains("t/default.err", '^me: message$');
ok 4, contains("t/default.err", '^me: WARNING: warning$');
ok 5, contains("t/default.err", '^me: die$');
ok 6, contains("t/default.err", '^me: debug-info$');
ok 7, !contains("t/default.err", '^me: trace-info$');
ok 8, 0 == -s "t/default.out";

unlink 't/default.out', 't/default.err';

