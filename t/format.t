#!./perl
###########################################################################
# $Id: format.t,v 1.1.4.1 2003/03/08 16:40:27 wendigo Exp $
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
# $Log: format.t,v $
# Revision 1.1.4.1  2003/03/08 16:40:27  wendigo
# Merged format and multiline carp changes
#
# Revision 1.1.2.2  2003/03/08 16:18:01  wendigo
# *** empty log message ***
#
# Revision 1.1.2.1  2002/12/13 04:24:46  wendigo
# Code to test logxxx formatting.
#
#
###########################################################################

use Test;
use Log::Agent;

BEGIN { plan tests => 4 }

open(FOO, "t/frank");
eval { logdie "error: %m" };
ok($@ =~ /Error: $!/i);

eval { logdie "100%% pure, %s lard", "snowy" };
ok($@ =~ /100\% pure, snowy lard/);

eval { logdie "because %d is the magic number", 0x03 };
ok($@ =~ /Because 3 is the magic number/);

eval { logdie 'night of the living %*2$x', 233495723, 4 };
skip($] < 5.008 ? "pre 5.8.0" : 0, $@ =~ /Night of the living dead/);

