#!./perl
###########################################################################
# $Id: file.t,v 0.4 2004/02/03 03:37:02 wendigo Exp $
###########################################################################
#
# file.t
#
# RCS Revision: $Revision: 0.4 $
# Date: $Date: 2004/02/03 03:37:02 $
#
# Copyright (C) 1999 Raphael Manfredi
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: file.t,v $
# Revision 0.4  2004/02/03 03:37:02  wendigo
# Replaced unnecessary file alias with actual file name.
#
# Revision 0.3  2002/02/23 06:28:56  wendigo
# Maintainer change
# - improved output redirection
# - switched to ok() from Test.pm
#
# Revision 0.2.1.1  2001/03/13 18:46:06  ram
# patch2: fixed bug for *BSD systems
#
# Revision 0.2  2000/11/06 19:30:34  ram
# Baseline for second Alpha release.
#
###########################################################################

use Test;
use Log::Agent;
require Log::Agent::Driver::File;
require 't/common.pl';

BEGIN { plan tests => 38 }

my $driver = Log::Agent::Driver::File->make();        # take all defaults
logconfig(-driver => $driver);

open(ORIGOUT, ">&STDOUT")   or die "can't dup STDOUT: $!\n";
open(STDOUT, ">t/file.out") or die "can't redirect STDOUT: $!\n";
open(ORIGERR, ">&STDERR")   or die "can't dup STDERR: $!\n";
open(STDERR, ">t/file.err") or die "can't redirect STDERR: $!\n";
select(ORIGERR); $| = 1;
select(ORIGOUT); $| = 1;

logerr "error";
logsay "message";

close STDOUT;
open(STDOUT, ">&ORIGOUT") or die "can't restore STDOUT: $!\n";
close STDERR;
open(STDERR, ">&ORIGERR") or die "can't restore STDERR: $!\n";
select(STDOUT);

ok(contains("t/file.err", '\d Error$'));
ok(! contains("t/file.out", 'Error'));
ok(contains("t/file.err", '\d Message$'));
ok(! contains("t/file.out", 'Message'));

undef $Log::Agent::Driver;        # Cheat

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -showpid => 1,
    -stampfmt => sub { 'DATE' },
    -channels => {
        'error' => 't/file.err',
        'output' => 't/file.out'
    },
    -duperr => 1,
);
logconfig(-driver => $driver);

open(ORIGOUT, ">&STDOUT")   or die "can't dup STDOUT: $!\n";
open(STDOUT, ">t/file.out") or die "can't redirect STDOUT: $!\n";
open(ORIGERR, ">&STDERR")   or die "can't dup STDERR: $!\n";
open(STDERR, ">t/file.err") or die "can't redirect STDERR: $!\n";
select(ORIGERR); $| = 1;
select(ORIGOUT); $| = 1;

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

close STDOUT;
open(STDOUT, ">&ORIGOUT") or die "can't restore STDOUT: $!\n";
close STDERR;
open(STDERR, ">&ORIGERR") or die "can't restore STDERR: $!\n";
select(STDOUT);

ok($@);

ok(contains("t/file.err", '^DATE me\[\d+\]: error$'));
ok(contains("t/file.out", 'ERROR: error'));
ok(contains("t/file.out", '^DATE me\[\d+\]: message$'));
ok(! contains("t/file.err", 'message'));
ok(contains("t/file.err", '^DATE me\[\d+\]: warning$'));
ok(contains("t/file.out", 'WARNING: warning'));
ok(contains("t/file.err", '^DATE me\[\d+\]: die$'));
ok(contains("t/file.out", 'FATAL: die'));

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;        # Cheat

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -stampfmt => sub { 'DATE' },
    -channels => {
        'error' => 't/file.err',
        'output' => 't/file.out'
    },
);
logconfig(-driver => $driver);

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

ok($@);

ok(contains("t/file.err", '^DATE me: error$'));
ok(! contains("t/file.out", 'error'));
ok(contains("t/file.out", '^DATE me: message$'));
ok(! contains("t/file.err", 'message'));
ok(contains("t/file.err", '^DATE me: warning$'));
ok(! contains("t/file.out", 'warning'));
ok(contains("t/file.err", '^DATE me: die$'));
ok(! contains("t/file.out", 'die'));

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;  # Cheat
open(FILE, '>>t/file.err'); # Needs appending, for OpenBSD

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -magic_open => 1,
    -channels => {
        'error' => '>>t/file.err',
    },
);
logconfig(-driver => $driver);

logerr "error";
logsay "should go to error";

close FILE;

ok(! -e '>&main::FILE');
ok(-e 't/file.err');
ok(contains("t/file.err", 'me: error$'));
ok(contains("t/file.err", 'me: should go to'));

unlink 't/file.err';

#
# Test file permissions
#

$driver = Log::Agent::Driver::File->make(
    -file => 'file.out',
    -perm => 0666
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0666));

unlink 'file.out';

$driver = Log::Agent::Driver::File->make(
    -file => 'file.out',
    -perm => 0644
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0644));

unlink 'file.out';

$driver = Log::Agent::Driver::File->make(
    -file => 'file.out',
    -perm => 0640
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0640));

#
# and with magic_open
#

unlink 'file.out';
$driver = Log::Agent::Driver::File->make(
    -file       => 'file.out',
    -perm       => 0666,
    -magic_open => 1
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0666));

unlink 'file.out';

$driver = Log::Agent::Driver::File->make(
    -file       => 'file.out',
    -perm       => 0644,
    -magic_open => 1
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0644));

unlink 'file.out';

$driver = Log::Agent::Driver::File->make(
    -file       => 'file.out',
    -perm       => 0640,
    -magic_open => 1
);
logconfig(-driver => $driver);
logsay "HONK HONK!";

ok(perm_ok('file.out', 0640));

unlink 'file.out';

#
# Test file permissions with multiple channels
#

$driver = Log::Agent::Driver::File->make(
    -channels => {
        output => 'file.out',
        error  => 'file.err',
        debug  => 'file.dbg'
    },
    -chanperm => {
        output => 0666,
        error  => 0644,
        debug  => 0640
    }
);
logconfig(-driver => $driver, -debug => 10);
logsay "HONK HONK!";
logerr "HONK HONK!";
logdbg 'debug', "HONK HONK!";

ok(perm_ok('file.out', 0666));
ok(perm_ok('file.err', 0644));
ok(perm_ok('file.dbg', 0640));

unlink 'file.out', 'file.err', 'file.dbg';

#
# and, again, with magic_open
#

$driver = Log::Agent::Driver::File->make(
    -channels => {
        output => 'file.out',
        error  => 'file.err',
        debug  => 'file.dbg'
    },
    -chanperm => {
        output => 0666,
        error  => 0644,
        debug  => 0640
    },
    -magic_open => 1
);
logconfig(-driver => $driver, -debug => 10);
logsay "HONK HONK!";
logerr "HONK HONK!";
logdbg 'debug', "HONK HONK!";

ok(perm_ok('file.out', 0666));
ok(perm_ok('file.err', 0644));
ok(perm_ok('file.dbg', 0640));

unlink 'file.out', 'file.err', 'file.dbg';


