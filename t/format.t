#!./perl
###########################################################################
# $Id: format.t,v 1.4 2005/10/02 16:47:29 wendigo Exp $
###########################################################################
#
# format.t
#
# RCS Revision: $Revision: 1.4 $
# Date: $Date: 2005/10/02 16:47:29 $
#
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: format.t,v $
# Revision 1.4  2005/10/02 16:47:29  wendigo
# Fixed formatting behavior for strings that contain "%%" without any other
# formating characters.
#
# Revision 1.3  2003/09/27 15:27:00  wendigo
# Saved $! before testing %m since perl-5.8.1 seems to modify $! during
# a call to logerr().
#
# Revision 1.2  2003/09/27 15:19:24  wendigo
# Tests for sprintf-like formatting.
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

BEGIN { plan tests => 7 }

open(FOO, "t/frank");
my $errstr = $!;
eval { logdie "error: %m" };
ok($@ =~ /Error: $errstr/i);
close FOO;

eval { logdie "100%% pure, %s lard", "snowy" };
ok($@ =~ /100\% pure, snowy lard/);

eval { logdie "5%% Nation of Lumps in My Oatmeal" };
ok($@ =~ /5% Nation of Lumps in My Oatmeal/);

eval { logdie "10%% inspiration, 90%% frustration" };
ok($@ =~ /10% inspiration, 90% frustration/);

eval { logdie "%-10s, %10s", 'near', 'far' };
ok($@ =~ /Near      ,        far/);

eval { logdie "because %d is the magic number", 0x03 };
ok($@ =~ /Because 3 is the magic number/);

eval { logdie 'night of the living %*2$x', 233495723, 4 };
skip($] < 5.008 ? "pre 5.8.0" : 0, $@ =~ /Night of the living dead/);

