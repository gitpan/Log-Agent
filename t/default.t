#!./perl

#
# $Id: default.t,v 0.1.1.1 2000/03/05 22:24:55 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: default.t,v $
# Revision 0.1.1.1  2000/03/05 22:24:55  ram
# patch3: rewrote to use the new ok() routine
#
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
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

close STDOUT;
close STDERR;

ok 1, contains("t/default.err", '^Error$');
ok 2, !contains("t/default.out", '^Error$');
ok 3, contains("t/default.out", '^Message$');
ok 4, !contains("t/default.err", '^Message$');

unlink 't/default.out', 't/default.err';

