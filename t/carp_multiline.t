#!./perl
###########################################################################
# $Id: carp_multiline.t,v 1.2 2003/09/27 15:19:47 wendigo Exp $
###########################################################################
#
# format.t
#
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 2003/09/27 15:19:47 $
#
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: carp_multiline.t,v $
# Revision 1.2  2003/09/27 15:19:47  wendigo
# Tests for multi-line error messages.
#
# Revision 1.1.2.2  2003/03/08 16:18:01  wendigo
# *** empty log message ***
#
# Revision 1.1.2.1  2002/12/13 04:54:42  wendigo
# Code to test multiline error messages.
#
# Revision 1.1.2.1  2002/12/13 04:24:46  wendigo
# Code to test logxxx formatting.
#
#
###########################################################################

use Test;
use Carp;
use Log::Agent;

BEGIN { plan tests => 1 }

eval { croak "Yo\nla\ntengo" }; $die1 = $@; eval { logcroak "Yo\nla\ntengo" };
$die2 = $@;
$die1 =~ s/^\s+eval.*\n//m;

ok($die1 eq $die2);

