#!./perl

#
# $Id: carp_silent.t,v 0.1.1.1 2000/10/01 20:00:38 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp_silent.t,v $
# Revision 0.1.1.1  2000/10/01 20:00:38  ram
# patch8: created.
#
# Revision 0.1.1.1  2000/03/05 22:24:29  ram
# patch3: created
#
# Revision 0.1  1999/12/07 21:09:45  ram
# Baseline for first alpha release.
#
# $EndLog$
#

print "1..2\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::Silent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/file.err") || die "can't redirect STDOUT: $!\n";

my $driver = Log::Agent::Driver::Silent->make();
logconfig(-driver => $driver);

sub test {
	logcarp "none";
	logcroak "test";
}

my $line = __LINE__ + 1;
test();

sub END {
	ok 1, !contains("t/file.err", "none");
	ok 2, contains("t/file.err", "test at t/carp_silent.t line $line");

	unlink 't/file.out', 't/file.err';
	exit 0;
}

