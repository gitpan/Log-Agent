#!./perl

#
# $Id: carp_default.t,v 0.1.1.1 2000/10/01 20:00:33 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp_default.t,v $
# Revision 0.1.1.1  2000/10/01 20:00:33  ram
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

use Log::Agent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/file.err") || die "can't redirect STDOUT: $!\n";

do 't/carp.pl';

