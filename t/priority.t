#!./perl

#
# $Id: priority.t,v 1.1 2002/03/09 16:16:55 wendigo Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: priority.t,v $
# Revision 1.1  2002/03/09 16:16:55  wendigo
# New maintainer
#
# Revision 0.2.1.1  2001/03/13 18:48:06  ram
# patch2: fixed bug for *BSD systems
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..5\n";

require 't/code.pl';
sub ok;

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
logconfig(
	-driver		=> $driver,
	-priority	=> [ -display => '<$priority/$level>', -prefix => 1 ],
	-level		=> 12,
);

logerr "error string";
logsay "notice string";
logcarp "carp string";
logdbg 'info:12', "info string";

ok 1, contains("t/file.err", "<error/3> error string");
ok 2, !contains("t/file.err", "notice string");
ok 3, contains("t/file.err", "<warning/4> carp string");
ok 4, contains("t/file.out", "<notice/6> notice string");
ok 5, contains("t/file.err", "<info/12> info string");

unlink 't/file.out', 't/file.err';

