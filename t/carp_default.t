#!./perl

#
# $Id: carp_default.t,v 0.2 2000/11/06 19:30:33 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp_default.t,v $
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

use Log::Agent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/file.err") || die "can't redirect STDOUT: $!\n";

do 't/carp.pl';

