#
# $Id: Agent.pm,v 0.1.1.9 2000/10/01 20:02:29 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Agent.pm,v $
# Revision 0.1.1.9  2000/10/01 20:02:29  ram
# patch8: changed version number
#
# Revision 0.1.1.8  2000/10/01 19:49:22  ram
# patch8: added support for Devel::Datum
# patch8: new logcarp, logxcarp and logxcroak interface
#
# Revision 0.1.1.7  2000/07/04 20:02:59  ram
# patch7: forgot to increase version number at last patch
#
# Revision 0.1.1.6  2000/07/04 20:00:55  ram
# patch6: was missing default init check before calling logwrite()
#
# Revision 0.1.1.5  2000/06/20 21:21:45  ram
# patch5: added logcroak()
# patch5: new logwrite() routine for upper-level apps
# patch5: fixed arg processing to avoid dying on 2nd calls to logconfig()
# patch5: fixed typos in debug init and man page
#
# Revision 0.1.1.4  2000/03/30 19:24:04  ram
# patch4: updated version number
#
# Revision 0.1.1.3  2000/03/05 22:20:48  ram
# patch3: updated version number
#
# Revision 0.1.1.2  1999/12/09 17:30:40  ram
# patch2: wrote two versions of format_args and eval proper one
#
# Revision 0.1.1.1  1999/12/08 21:51:38  ram
# patch1: forgot that /(?<!)/ is a 5.005 feature
#
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;
require Exporter;

########################################################################
package Log::Agent;

use vars qw($VERSION $Driver $Prefix $Trace $Debug $Confess $Caller $DATUM);
use AutoLoader 'AUTOLOAD';
use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw(
	logconfig
	logconfess logcroak logcarp logxcroak logxcarp
	logsay logerr logwarn logdie logtrc logdbg
);
@EXPORT_OK = qw(
	logwrite
);

require Log::Agent::Message;

$VERSION = '0.108';

###
### Utilities
###
### (not autoloaded due to use of different versions)
###

#
# format_args
#
# Format arguments using sprintf() if there is more than one, taking the
# first as the format. Otherwise, we take only its first and only argument.
#
# Returns a Log::Agent::Message object, which, when stringified, prints
# the string itself.
#
# We process syslog's %m macro as being the current error message ($!) in
# the first argument only. Doing it at this level means it will be supported
# independently from the driver they'll choose. It's also done BEFORE any
# log-related system call, thus ensuring that $! retains its original value.
#
# If caller information is wanted, add it to the log message according to
# the specifications chosen at logconfig() time.
#
if ($] >= 5.005) { eval q{				# if VERSION >= 5.005

# 5.005 and later version grok /(?<!)/
sub format_args {
	my $fmt = shift;
	$fmt =~ s/((?<!%)(?:%%)*)%m/$!/g;
	my $str = Log::Agent::Message->make(@_ ? sprintf($fmt, @_) : $fmt);
	$Caller->insert($str) if $Caller;
	return $str;
}

}} else { eval q{						# else /* VERSION < 5.005 */

# pre-5.005 does not grok /(?<!)/
sub format_args {
	my $fmt = shift;
	$fmt =~ s/%%/\01/g;
	$fmt =~ s/%m/$!/g;
	$fmt =~ s/\01/%%/g;
	my $str = Log::Agent::Message->make(@_ ? sprintf($fmt, @_) : $fmt);
	$Caller->insert($str) if $Caller;
	return $str;
}

}}										# endif /* VERSION >= 5.005 */

###
### Priority/level mappings
###
### (not autoloaded due to the use of lexical variables)
###

my @basic_prio = qw(
	alert critical
	error error
	warning warning
	notice notice
	info info);

#
# prio_from_level
#
# Given a level, compute suitable priority.
#
sub prio_from_level {
	my ($level) = @_;
	return 'emergency' if $level < 0;
	return 'debug' if $level > @basic_prio;
	return $basic_prio[$level];
}

my %basic_level = (
	'em'	=> 1,		# emergency
	'al'	=> 1,		# alert
	'cr'	=> 1,		# critical
	'er'	=> 2,		# error
	'wa'	=> 4,		# warning
	'no'	=> 6,		# notice
	'in'	=> 8,		# info
	'de'	=> 10,		# debug
);

#
# level_from_prio
#
# Given a syslog priority, compute suitable level.
#
sub level_from_prio {
	my ($prio) = @_;
	my $canonical = lc(substr($prio, 0, 2));
	return 10 unless exists $basic_level{$canonical};
	return $basic_level{$canonical};
}

1;
__END__

#
# logconfig
#
# Configure the logging system at the application level. By default, logging
# uses the Log::Agent::Driver::Default driver.
#
# Available options (case insensitive):
#
#   -PREFIX => string             logging prefix/tag to use, for Default agent
#   -DRIVER => object             object heir of Log::Agent::Driver
#   -TRACE => level               trace level
#   -DEBUG => level               debug level
#   -LEVEL => level               specifies common trace/debug level
#	-CONFESS => flag              whether to automatically confess on logdie
#	-CALLER => listref            info from caller to add and where
#
# For -CALLER, allowed keys are documented in the Log::Agent::Caller's make().
#
sub logconfig {
	my (%args) = @_;
	my $calldef;

	my %set = (
		-prefix			=> \$Prefix,		# Only for Default init
		-driver			=> \$Driver,
		-trace			=> \$Trace,
		-debug			=> \$Debug,
		-level			=> [\$Trace, \$Debug],
		-confess		=> \$Confess,
		-caller			=> \$calldef,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		if		(ref $vset eq 'SCALAR')		{ $$vset = $val }
		elsif	(ref $vset eq 'ARRAY')		{ map { $$_ = $val } @$vset }
		elsif	(ref $vset eq 'REF')		{ $$vset = $val }
		else								{ die "bug in logconfig" }
	}

	unless (defined $Driver) {
		require Log::Agent::Driver::Default;
		# Keep only basename for default prefix
		$Prefix =~ s|^.*/(.*)|$1| if defined $Prefix;
		$Driver = Log::Agent::Driver::Default->make($Prefix);
	}

	$Prefix = $Driver->prefix;
	$Trace = level_from_prio($Trace) if defined $Trace && $Trace =~ /^\D+/;
	$Debug = level_from_prio($Debug) if defined $Debug && $Debug =~ /^\D+/;

	if (defined $calldef) {
		require Log::Agent::Caller;
		$Caller = Log::Agent::Caller->make(-offset => 2, @{$calldef});
	};

	# Install interceptor if needed
	DATUM_is_here() if defined $DATUM && $DATUM;
}

#
# inited
#
# Returns whether Log::Agent was inited.
# NOT exported, must be called as Log::Agent::inited().
#
sub inited {
	return 0 unless defined $Driver;
	return ref $Driver ? 1 : 0;
}

#
# DATUM_is_here		-- undocumented, but for Devel::Datum
#
# Tell Log::Agent that the Devel::Datum package was loaded and configured
# for debug.
#
# If there is a driver configured already, install the interceptor.
# Otherwise, record that DATUM is here and the interceptor will be installed
# by logconfig().
#
# NOT exported, must be called as Log::Agent::DATUM_is_here().
#
sub DATUM_is_here {
	$DATUM = 1;
	return unless defined $Driver;
	return if ref $Driver eq 'Log::Agent::Driver::Datum';

	#
	# Install the interceptor.
	#

	require Log::Agent::Driver::Datum;
	$Driver = Log::Agent::Driver::Datum->make($Driver);
}

#
# log_default
#
# Initialize a default logging driver.
#
sub log_default {
	return if defined $Driver;
	logconfig();
}

#
# logconfess
#
# Die with a full stack trace
#
sub logconfess {
	my $str = format_args(@_);
	&log_default;
	$Driver->logconfess($str);
	bug("back from logconfess in driver $Driver\n");
}

#
# logcroak
#
# Fatal error, from the perspective of our caller
# Error is logged, and then we die.
#
sub logcroak {
	goto &logconfess if $Confess;		# Redirected when -confess
	my $str = format_args(@_);
	&log_default;
	$Driver->logxcroak(0, $str);
	bug("back from logxcroak in driver $Driver\n");
}

#
# logxcroak
#
# Same a logcroak, but with a specific additional offset.
#
sub logxcroak {
	my $offset = shift;
	goto &logconfess if $Confess;		# Redirected when -confess
	my $str = format_args(@_);
	&log_default;
	$Driver->logxcroak($offset, $str);
	bug("back from logxcroak in driver $Driver\n");
}

#
# logdie
#
# Fatal error
# Error is logged, and then we die.
#
sub logdie {
	goto &logconfess if $Confess;		# Redirected when -confess
	my $str = format_args(@_);
	&log_default;
	$Driver->logdie($str);
	bug("back from logdie in driver $Driver\n");
}

#
# logerr
#
# Log error
#
sub logerr {
	my $str = format_args(@_);
	&log_default;
	$Driver->logerr($str);
}

#
# logcarp
#
# Warning, from the perspective of our caller
#
sub logcarp {
	my $str = format_args(@_);
	&log_default;
	$Driver->logxcarp(0, $str);
}

#
# logxcarp
#
# Same a logcarp, but with a specific additional offset.
#
sub logxcarp {
	my $offset = shift;
	my $str = format_args(@_);
	&log_default;
	$Driver->logxcarp($offset, $str);
}

#
# logwarn
#
# Log warning
#
sub logwarn {
	my $str = format_args(@_);
	&log_default;
	$Driver->logwarn($str);
}

#
# logsay
#
# Unconditionally log message
#
sub logsay {
	my $str = format_args(@_);
	&log_default;
	$Driver->logsay($str);
}

#
# logtrc		-- frozen
#
# Trace the message if trace level is set high enough.
# Trace level must either be a single digit or "priority" or "priority:digit".
#
sub logtrc {
	my ($id, @args) = @_;
	my ($prio, $level) = priority($id);
	return if !defined($Trace) || $level > $Trace;
	my $str = format_args(@args);
	&log_default;
	$Driver->logwrite('output', $prio, $level, $str);
}

#
# logdbg		-- frozen
#
# Emit debug message if debug level is set high enough.
# Debug level must either be a single digit or "priority" or "priority:digit".
#
sub logdbg {
	my ($id, @args) = @_;
	my ($prio, $level) = priority($id);
	return if !defined($Debug) || $level > $Debug;
	my $str = format_args(@args);
	&log_default;
	$Driver->logwrite('debug', $prio, $level, $str);
}

###
### Utilities
###

#
# logwrite		-- not exported by default
#
# Write message to the specified channel, at the given priority.
# This routine is used by both logtrc() and logdbg() and may be redefined.
#
sub logwrite {
	my ($channel, $id, @args) = @_;
	my ($prio, $level) = priority($id);
	my $str = format_args(@args);
	&log_default;
	$Driver->logwrite($channel, $prio, $level, $str);
}

#
# priority
#
# Decompiles priority which can be either a single digit, a "priority" string
# or a "priority:digit" string. Returns the priority (computed if none) and
# the level (computed if none).
#
sub priority {
	my ($id) = @_;
	return (prio_from_level($id), $id) if $id =~ /^\d+$/;
	return ($1, $2) if $id =~ /^([^:]+):(\d+)$/;
	return ($id, level_from_prio($id));
}

#
# bug
#
# Log bug, and die.
#
sub bug {
	my $str = format_args(@_);
	logerr("BUG: $str");
	die "${Prefix}: $str\n";
}

=head1 NAME

Log::Agent - logging agent

=head1 SYNOPSIS

 use Log::Agent;            # in all reusable components
 logerr "error";
 logtrc "notice:12", "notice that" if ...;
 logdie "log and die";

 use Log::Agent;            # in application's main
 logconfig(-prefix => $0);  # simplest, uses default driver

 use Log::Agent;                    # another more complex example
 require Log::Agent::Driver::File;  # logging made to file
 logconfig(-driver =>
     Log::Agent::Driver::File->make(
         -prefix      => $0,
         -showpid     => 1,
         -channels    => {
             'error'  => "$0.err",
             'output' => "$0.out",
             'debug'  => "$0.dbg",
         },
     )
 );

=head1 DESCRIPTION

The Log::Agent module provides an abstract layer for logging and tracing,
which is independant from the actual method used to physically perform
those activities. It acts as an agent (hence the name) that collects
the requests and delegates processing to a sublayer: the logging driver.

The Log::Agent module is meant to be used in all reusable components,
since they cannot know in advance how the application which ends up
using them will perform its logging activities: either by emitting
messages on stdout and errors on stderr, or by directing messages
to logfiles, or by using syslog(3).

The logging interface is common for all the logging drivers, and is
therefore the result of a compromise between many logging schemes:
any information given at this level must be either handled by all
drivers, or may be ignored depending on the application's final choice.

WARNING: THIS INTERFACE IS STILL VERY ALPHA AND IS SUBJECT TO CHANGE
DEPENDING ON THE FEEDBACK I SHALL GET FROM USERS AND FROM MY OWN
EXPERIENCE USING IT, WITHOUT ANY BACKWARD COMPATIBILITY ASSURANCE.

=head1 PRIORITIES AND LEVEL

The Log::Agent module can use both priorities (as defined by syslog(3))
or logging levels, or either, in which case there is an implicit
computation of the missing item. Here are the known priorities (which
may be abbreviated to the first 2 letters, in a case-insensitive manner)
and their corresponding logging level:

    emergency   0
    alert       0
    critical    1
    error       2
    warning     4
    notice      6
    info        8
    debug       10 

A logging level is defined as being a threshold: any level lesser than
or equal to that threshold will be logged.

Anywhere where a I<priority> is expected, one may specify a number taken
as a logging level or a string taken as a priority. If the default
mapping outlined above is not satisfactory, it can be redefined by
specifying, for instance C<"notice:9">. It will be taken as being of
level 9, but with a C<notice> priority nonetheless, not C<info> as
it would have been implicitely determined otherwise.

At the Log::Agent level, it is possible to define a trace level and a
debug level. Only the messages below those levels (inclusive) will be handed
out to the underlying driver for logging. They are used by the logtrc()
and logdbg() routines, respectively.

=head1 CHANNELS

The Log::Agent class defines three logging channels, which are C<error>,
C<output> and C<debug>. Depending on the driver used for logging, those
channels are ignored (typically with syslog()) or may be implicitely defined
(default logging, i.e. the one achieved by the Log::Agent::Driver::Default
driver, remaps C<error> to stderr, C<output> and C<debug> to stdout).

=head1 INTERFACE

Anywhere a I<message> is expected, it can be a single string, or a
printf()-like format string followed by the required arguments. The special
macro C<%m> is handled directly by Log::Agent and is replaced by the string
version of $!, which is the last error message returned by the last failing
system call.

B<NOTE>: There should not be any trailing "\n" in the I<message> strings, nor
any embededed one, although this is not enforced. Remember that the main
purpose of Log::Agent is to specify logging messages in a standard way!
Therefore, most of the time, a "should" should be read as "must" and "should
not" as "must not", which is the strongest interdiction form available in
English, as far as I know.

Here are valid I<message> examples:

    "started since $time"
    "started since %s", $time
    "fork: %m"

The follwing logging interface is made available to modules:

=over

=item logdbg I<priority>, I<message>

Debug logging of I<message> to the C<debug> channel.
You may specify any priority you want, i.e.
a C<debug> priority is not enforced here. You may even specify C<"notice:4">
if you wish, to have the message logged if the debug level is set to 4 or less.
If handed over to syslog(3), the message will nonetheless be logged at the
C<notice> priority.

=item logtrc I<priority>, I<message>

Trace logging of I<message> to the C<output> channel.
Like logdbg() above, you are not restricted
to the C<info> priority. This routine checks the logging level (either
explicit as in C<"info:14"> or implicit as in C<"notice">) against the
trace level.

=item logsay I<message>

Unconditionally log the message at the C<notice> priority to the C<output>
channel.
The logging always takes place, but only if the routine is called.
This means you can still say:

    logsay "some trace message" if $verbose;

and control whether the message is emitted by using some external configuration
for your module (e.g. by adding a -verbose flag to the creation routine of
your class).

=item logwarn I<message>

Log a warning message at the C<warning> priority to the C<error> channel.

=item logcarp I<message>

Same as logwarn(), but issues a Carp::carp(3) call instead, which will
warn from the perspective of the routine's caller.

=item logerr I<message>

Log an error message at the C<error> priority to the C<error> channel.

=item logdie I<message>

Log a fatal message at the C<critical> priority to the C<error> channel,
and then dies.

=item logconfess I<message>

Same as logdie(), but issues a Carp::confess(3) call instead.
It is possible to configure the Log::Agent module via the C<-confess> switch
to automatically redirect a logdie() to logconfess(), which is invaluable
during unit testing.

=item logcroak I<message>

Same as logdie(), but issues a Carp::croak(3) call instead.
It is possible to configure the Log::Agent module via the C<-confess> switch
to automatically redirect a logcroak() to logconfess(), which is invaluable
during unit testing.

=item Log::Agent::inited

Returns true when C<Log::Agent> was initialized, either explicitely via
a logconfig() or implicitely via any logxxx() call.

=back

Modules sometimes wish to report errors from the perspective of their
caller's caller, not really their caller.  The following interface is
therefore provided:

=over

=item logxcarp I<offset>, I<message>

Same a logcarp(), but with an additional offset to be applied on the
stack.  To warn one level above your caller, set it to 1.

=item logxcroak I<offset>, I<message>

Same a logcroak(), but with an additional offset to be applied on the
stack.  To report an error one level above your caller, set it to 1.

=back

For applications that wish to implement a debug layer on top of Log::Agent,
the following routine is provided.  Note that it is not imported by default,
i.e. it needs to be explicitely mentionned at C<use> time, since it is not
meant to be used directly under regular usage.

=over

=item logwrite I<channel>, I<priority>, I<message>

Unconditionally write the I<message> at the given I<priority> on I<channel>.
The channel can be one of C<debug>, C<error> or C<output>.

=back

At the application level, one needs to commit once and for all about the
logging scheme to be used. This is done thanks to the logconfig() routine
which takes the following switches, in alphabetical order:

=over

=item C<-caller> => [ I<parameters> ]

Request that caller information (relative to the logxxx() call) be part
of the log message. The given I<parameters> are handed off to the
creation routine of Log::Agent::Caller(3) and are documented there.

I usually say something like:

	-caller => [ -display => '($sub/$line)' ]

which I find informative enough. On occasion, I found myself using more
complex sequences.

=item C<-confess> => I<flag>

When true, all logdie() calls will be automatically masqueraded as
logconfess().

=item C<-debug> => I<priority or level>

Sets the priority threshold (can be expressed as a string or a number, the
string being mapped to a logging level as described above in
B<PRIORITIES AND LEVEL>) for logdbg() calls.

Calls tagged with a level less than or equal to the given threshold will
pass through, others will return prematurely without logging anything.

=item C<-driver> => I<driver_object>

This switch defines the driver object to be used, which must be an heir of
the Log::Agent::Driver class. See L<Log::Agent::Driver(3)> for a list
of the available drivers.

=item C<-level> => I<priority or level>

Specifies both C<-debug> and C<-trace> levels at the same time, to a
common value.

=item C<-prefix> => I<name>

Defines the application name which will be pre-pended to all messages, followed
by C<": "> (a colon and a space). Using this switch alone will configure
the default driver to use that prefix (stripped down to its basename component).

When a driver object is used, the C<-prefix> switch is kept at the Log::Agent
level only and is not passed to the driver: it is up to the driver's creation
routine to request the C<-prefix>. Having this information in Log::Agent
enables the module to die on critical errors with that error prefix, since
it cannot rely on the logging driver for that, obviously.

=item C<-trace> => I<priority or level>

Same a C<-debug> but for logtrc() calls only.

=back

=head1 KNOWN LIMITATIONS

The following limitations exist in this early version. They might be addressed
in future versions if they are perceived as annoying limitatons instead of
being just documented ones. :-)

=over

=item *

A module which calls logdie() may have its die trapped if called from
within an eval(), but unfortunately, the value of $@ is unpredictable:
it may be prefixed or not depending on the driver used. This is harder to
fix as one might think of at first glance.

=item *

Some drivers lack customization and hardwire a few things that come from
my personal taste, like the prefixing done when I<duperr> is set in
Log::Agent::Driver::File, or the fact that the C<debug> and C<output> channels
are merged as one in the Log::Agent::Driver::Default driver.

=item *

When using logcroak() or logconfess(), the place where the call was made
can still be visible when -caller is used, since the addition of the
caller information to the message is done before calling the logging driver.
Is this a problem?

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Carp(3).

=cut
