#!./perl

#
# $Id: carp_file.t,v 0.1.1.1 2000/10/01 20:00:36 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp_file.t,v $
# Revision 0.1.1.1  2000/10/01 20:00:36  ram
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
