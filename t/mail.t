###########################################################################
# $Id: mail.t,v 1.1 2002/05/12 08:56:47 wendigo Exp $
###########################################################################
#
# fork.t
#
# RCS Revision: $Revision: 1.1 $
# Date: $Date: 2002/05/12 08:56:47 $
#
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: mail.t,v $
# Revision 1.1  2002/05/12 08:56:47  wendigo
# Initial revision
#
#
###########################################################################

use strict;
use Test;
require 't/common.pl';

BEGIN { 
    eval "require Mail::Mailer";
    if ($@) {
        print "1..0 # Skipped: Mail::Mailer not found\n";
        exit;
    }
    plan tests => 13;
}

use Log::Agent;
require Log::Agent::Driver::Mail;
my $driver = Log::Agent::Driver::Mail->make(
    -to => 'una@example.net',
    -from => 'ellis@example.net',
    -subject => 'TEST',
    -cc => 'stimps@example.net',
    -bcc => 'krista@example.net',
    -priority => 'bulk',
    -reply_to => 'smilodog@example.net',
    -mailer => [ qw( test ) ]
);
logconfig( -driver => $driver );

open(ORIGOUT, ">&STDOUT")           or die "can't dup STDOUT: $!\n";
open(STDOUT, ">t/mail_std.out") or die "can't redirect STDOUT: $!\n";
select(ORIGOUT); $| = 1;

logerr "ellis on bed";
logsay "gotta biscuit?";
logtrc 'debug', "heel"; # message lost in transit
logwarn "beware the smilodog";
eval { logdie "new stuffed animal" };

close STDOUT;
open(STDOUT, ">&ORIGOUT")           or die "can't restore STDOUT: $!\n";
select(STDOUT);

ok($@);

# default driver output
ok(contains("t/mail_std.out",
        '^to:( una@example.net |stimps@example.net |krista@example.net)+$'));
ok(contains("t/mail_std.out", '^To: una@example.net$'));
ok(contains("t/mail_std.out", '^From: ellis@example.net$'));
ok(contains("t/mail_std.out", '^Cc: stimps@example.net$'));
ok(contains("t/mail_std.out", '^Bcc: krista@example.net$'));
ok(contains("t/mail_std.out", '^Reply-to: smilodog@example.net$'));
ok(contains("t/mail_std.out", '^Subject: TEST$'));
ok(contains("t/mail_std.out", '^Priority: bulk$'));

ok(contains("t/mail_std.out", '^ellis on bed$'));
ok(contains("t/mail_std.out", '^gotta biscuit\?$'));
ok(contains("t/mail_std.out", '^new stuffed animal$'));
ok(contains("t/mail_std.out", '^beware the smilodog$'));

unlink 't/mail_std.out';


