#!./perl

#
# $Id: tag_string.t,v 1.1 2002/03/09 16:16:55 wendigo Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: tag_string.t,v $
# Revision 1.1  2002/03/09 16:16:55  wendigo
# New maintainer
#
# Revision 0.2.1.1  2001/03/13 18:49:29  ram
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..2\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Tag::String;

unlink 't/file.out', 't/file.err';

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
my $t1 = Log::Agent::Tag::String->make(-value => "<tag #1>");
my $t2 = Log::Agent::Tag::String->make(-value => "<tag #2>", -postfix => 1);

logconfig(
	-driver		=> $driver,
	-tags		=> [$t1],
);

logerr "error string";

use Log::Agent qw(logtags);
my $tags = logtags;
$tags->append($t2);

logwarn "warn string";

ok 1, contains("t/file.err", '<tag #1> error string$');
ok 2, contains("t/file.err", '<tag #1> warn string <tag #2>$');

unlink 't/file.out', 't/file.err';

