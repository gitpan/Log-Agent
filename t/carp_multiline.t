#!./perl
###########################################################################
# $Id: carp_multiline.t,v 1.1.4.1 2003/03/08 16:40:27 wendigo Exp $
###########################################################################
#
# format.t
#
# RCS Revision: $Revision: 1.1.4.1 $
# Date: $Date: 2003/03/08 16:40:27 $
#
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: carp_multiline.t,v $
# Revision 1.1.4.1  2003/03/08 16:40:27  wendigo
# Merged format and multiline carp changes
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

