#!./perl

#
# $Id: carp_file.t,v 1.1 2002/03/09 16:16:55 wendigo Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp_file.t,v $
# Revision 1.1  2002/03/09 16:16:55  wendigo
# New maintainer
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

use Log::Agent;
require Log::Agent::Driver::File;

unlink 't/file.out', 't/file.err';

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(-driver => $driver);

do 't/carp.pl';
