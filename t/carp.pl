#
# $Id: carp.pl,v 1.1 2002/03/09 16:16:55 wendigo Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: carp.pl,v $
# Revision 1.1  2002/03/09 16:16:55  wendigo
# New maintainer
#
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

print "1..11\n";

require 't/code.pl';
sub ok;

my $FILE = "t/carp.pl";

package OTHER;
use Log::Agent;
use Carp qw(carp cluck);

sub make { bless {}, shift }

sub intern {
	my $i = $_[1];
	logcarp "OTHER${i}::intern";
}

sub extern {
	my $i = $_[1];
	logxcarp 1, "OTHER${i}::extern";
}

package ROOT;
use Log::Agent;

sub make {
	my $self = bless {}, shift;
	$self->{other} = OTHER->make;
	return $self;
}

sub f {
	logcarp "ROOT::f";
}

sub g {
	logcarp "ROOT::g";
}

sub h {
	my $self = shift;
	my $o = $self->{other};
	$main::intern1 = __LINE__ + 1;
	$o->intern(1);
	$o->extern(1);
}

sub k {
	my $o = OTHER->make;
	$main::intern2 = __LINE__ + 1;
	$o->intern(2);
	$o->extern(2);
}

package SUBCLASS;
use Log::Agent;

@ISA = qw(ROOT);

sub g {
	logcarp "SUBCLASS::g";
}

package main;
use Carp qw(carp cluck);

sub intern {
	logcarp "main::intern";
}

sub extern {
	logxcarp 1, "main::extern";
}

sub wrap {
	$intern = __LINE__ + 1;
	intern;
	extern;
}

my $r = ROOT->make;
my $s = SUBCLASS->make;

my $file = "t/file.err";
my $base = __LINE__ + 1;		# First call below
$r->f;
$s->f;
$r->g;
$s->g;

ok 1, 1 == contains($file, sprintf "ROOT::f at $FILE line %d", $base+0);
ok 2, 2 == contains($file, sprintf "ROOT::f at $FILE line %d", $base+1);
ok 3, 3 == contains($file, sprintf "ROOT::g at $FILE line %d", $base+2);

ok 4, contains($file, sprintf "SUBCLASS::g at $FILE line %d", $base+3);

# Empty file
open(FILE, ">$file");
close FILE;

$base = __LINE__ + 1;		# First call below
$s->h;
ok 5, contains($file, "OTHER1::intern at $FILE line $intern1");
ok 6, contains($file, "OTHER1::extern at $FILE line $base");

$base = __LINE__ + 1;		# First call below
ROOT::g();
ok 7, contains($file, "ROOT::g at $FILE line $base");

$base = __LINE__ + 1;		# First call below
ROOT::k();
ok 8, contains($file, "OTHER2::intern at $FILE line $intern2");
ok 9, contains($file, "OTHER2::extern at $FILE line $base");

#
# This test would not work without the kludge fixing Carp's output
# in Log::Agent::Driver::carpmess.
#
$base = __LINE__ + 1;		# First call below
wrap;
ok 10, contains($file, "main::intern at $FILE line $intern");
ok 11, contains($file, "main::extern at $FILE line $base");

unlink 't/file.out', 't/file.err';

