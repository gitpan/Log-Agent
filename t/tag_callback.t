#!./perl

#
# $Id: tag_callback.t,v 0.2.1.2 2001/03/14 23:40:42 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: tag_callback.t,v $
# Revision 0.2.1.2  2001/03/14 23:40:42  ram
# patch5: was wrongly issuing test headers twice when skipping
#
# Revision 0.2.1.1  2001/03/13 18:48:52  ram
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

require 't/code.pl';
sub ok;

eval "require Callback";
if ($@) {
	print "1..0\n";
	exit 0;
}
print "1..2\n";

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Tag::Callback;

unlink 't/file.out', 't/file.err';

sub build_tag {
	return "<" . join(':', @_) . ">";
}

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);

my $c1 = Callback->new(\&build_tag, qw(a b c));
my $c2 = Callback->new(\&build_tag, qw(d e f));
my $t1 = Log::Agent::Tag::Callback->make(-callback => $c1);
my $t2 = Log::Agent::Tag::Callback->make(-callback => $c2, -postfix => 1);

logconfig(
	-driver		=> $driver,
	-tags		=> [$t1],
);

logerr "error string";

use Log::Agent qw(logtags);
my $tags = logtags;
$tags->prepend($t2);

logwarn "warn string";

ok 1, contains("t/file.err", '<a:b:c> error string$');
ok 2, contains("t/file.err", '<a:b:c> warn string <d:e:f>$');

unlink 't/file.out', 't/file.err';

