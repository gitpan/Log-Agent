#!./perl

#
# $Id: default.t,v 0.2 2000/11/06 19:30:34 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: default.t,v $
# Revision 0.2  2000/11/06 19:30:34  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..4\n";

require 't/code.pl';
sub ok;

use Log::Agent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/default.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/default.err") || die "can't redirect STDERR: $!\n";

logerr "error";
logsay "message";
logtrc 'debug', "debug";

close STDOUT;
close STDERR;

ok 1, contains("t/default.err", '^Error$');
ok 2, contains("t/default.err", '^Message$');
ok 3, !contains("t/default.err", '^Debug$');
ok 4, 0 == -s "t/default.out";

unlink 't/default.out', 't/default.err';

