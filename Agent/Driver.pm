#
# $Id: Driver.pm,v 0.1.1.1 2000/03/05 22:21:58 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Driver.pm,v $
# Revision 0.1.1.1  2000/03/05 22:21:58  ram
# patch3: added end marker before pod
#
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;

########################################################################
package Log::Agent::Driver;

#
# Ancestor for all Log::Agent drivers.
#

#
# Common attribute acccess, initialized via _init().
#
# prefix			the common (static) string info to prepend to messages
#

sub prefix		{ $_[0]->{'prefix'} }

#
# is_deferred
#
# Report routine as being deferred
#
sub is_deferred {
	require Carp;
	Carp::confess("deferred");
}

#
# ->make			-- deferred
#
# Creation routine.
#
sub make {
	&is_deferred;
}

#
# ->_init
#
# Common initilization routine
#
sub _init {
	my $self = shift;
	my ($prefix) = @_;
	$self->{'prefix'} = $prefix;		# Prefix info to prepend
}

my %level = (
	'c' => 1,
	'e' => 2,
	'w' => 4,
	'n' => 6,
);

#
# ->priority		-- frozen
#
# Return proper priority for emit() based on one of the following strings:
# "critical", "error", "warning", "notice". Those correspond to the hardwired
# strings for logconfess()/logdie(), logerr(), logwarn() and logsay().
#
# This routine is intended to be "frozen", i.e. it MUST NOT be redefined.
# Redefine map_pri() if needed, or don't call it in the first place.
#
sub priority {
	my $self = shift;
	my ($prio) = @_;
	my $level = $level{lc(substr($prio, 0, 1))} || 8;
	return $self->map_pri($prio, $level);
}

#
# ->emit			-- deferred
#
# Emit log entry, physically.
# A trailing "\n" is to be added if needed.
#
# $channel is one of 'debug', 'output', 'error' and can be used to determine
# where the emission of the log message should be done.
#
sub emit {
	my $self = shift;
	my ($channel, $priority, $logstring) = @_;
	local $\ = undef;
	&is_deferred;
}

#
# ->map_pri			-- may be redefined
#
# Convert a ("priority", level) tupple to a single priority token suitable
# for `emit'.
#
# This is driver-specific: drivers may ignore priority altogether thanks to
# the previous level-based filtering done (-trace and -debug switches in the
# Log::Agent configuration), choose to give precedence to levels over priority
# when "priority:level" was specified, or always ignore levels and only use
# "priority".
#
# The default is to ignore "priority" and "levels", which is suitable to basic
# drivers. Only those (ala syslog) which rely on post-filtering need to be
# concerned.
#
sub map_pri {
	my $self = shift;
	my ($priority, $level) = @_;
	return '';		# ignored for basic drivers
}

#
# ->prefix_msg		-- deferred
#
# Prefix message with driver-specific string, if necessary.
#
# This routine may or may not use common attributes like the fixed
# static prefix or the process's pid.
#
sub prefix_msg {
	my $self = shift;
	my ($str) = @_;
	&is_deferred;
}

#
# ->logconfess
#
# Confess fatal error
# Error is logged, and then we confess.
#
sub logconfess {
	my $self = shift;
	my ($str) = @_;
	$self->emit('error',
		$self->priority('critical'),
		$self->prefix_msg($str));
	require Carp;
	Carp::confess("$str\n");
}

#
# ->logdie
#
# Fatal error
# Error is logged, and then we die.
#
sub logdie {
	my $self = shift;
	my ($str) = @_;
	$self->emit('error',
		$self->priority('critical'),
		$self->prefix_msg($str));
	die "$str\n";
}

#
# logerr
#
# Log error
#
sub logerr {
	my $self = shift;
	my ($str) = @_;
	$self->emit('error',
		$self->priority('error'),
		$self->prefix_msg($str));
}

#
# logwarn
#
# Log warning
#
sub logwarn {
	my $self = shift;
	my ($str) = @_;
	$self->emit('error',
		$self->priority('warning'),
		$self->prefix_msg($str));
}

#
# logsay
#
# Unconditionally log message
#
sub logsay {
	my $self = shift;
	my ($str) = @_;
	$self->emit('output',
		$self->priority('notice'),
		$self->prefix_msg($str));
}

#
# logtrc
#
# Trace the message
#
sub logtrc {
	my $self = shift;
	my ($prio, $level, $str) = @_;
	$self->emit('output',
		$self->map_pri($prio, $level),
		$self->prefix_msg($str));
}

#
# logdbg
#
# Emit debug message
#
sub logdbg {
	my $self = shift;
	my ($prio, $level, $str) = @_;
	$self->emit('debug',
		$self->map_pri($prio, $level),
		$self->prefix_msg($str));
}

###
### Common time-stamping routines
###

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @days = qw(Sun Mon Tue Wed Thu Fri Sat);

#
# stamp_none
#
# No timestamp
#
sub stamp_none {
	return '';
}

#
# stamp_syslog
#
# Syslog-like stamping: "Oct 27 21:09:33"
#
sub stamp_syslog {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "%s %2d %.2d:%.2d:%.2d",
		$months[$mon], $mday, $hour, $min, $sec;
}

#
# stamp_date
#
# Date format: "[Fri Oct 22 16:23:10 1999]"
#
sub stamp_date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "[%s %s %2d %.2d:%.2d:%.2d %d]",
		$days[$wday], $months[$mon], $mday, $hour, $min, $sec, 1900 + $year;
}

#
# stamp_own
#
# Own format: "99/10/24 09:43:49"
#
sub stamp_own {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "%.2d/%.2d/%.2d %.2d:%.2d:%.2d",
		$year % 100, ++$mon, $mday, $hour, $min, $sec;
}

my %stamping = (
	'none'		=> \&stamp_none,
	'syslog'	=> \&stamp_syslog,
	'date'		=> \&stamp_date,
	'own'		=> \&stamp_own,
);

#
# ->stamping_fn
#
# Return proper time stamping function based on its 'tag' (would be stamp_tag).
# If tag is unknown, use stamp_own.
#
sub stamping_fn {
	my $self = shift;
	my ($tag) = @_;
	return $stamping{$tag} if defined $tag && defined $stamping{$tag};
	return \&stamp_own;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Driver - ancestor class for all Log::Agent drivers

=head1 SYNOPSIS

 @Log::Agent::Driver::XXX::ISA = qw(Log::Agent::Driver);

=head1 DESCRIPTION

The Log::Agent::Driver class is the root class from which all Log::Agent
drivers inherit. It is a I<deferred> class, meaning that it cannot
be instantiated directly. All the deferred routines need to be implemented
by its heirs to form a valid driver.

A I<deferred> routine is a routine whose signature and semantics (pre and
post conditions, formally) are specified, but not implemented. It allows
specification of high-level processings in terms of them, thereby factorizing
common code in the ancestors without loosing specialization benefits.

=head1 DRIVER LIST

The following drivers are currently fully implemented:

=over

=item Log::Agent::Driver::Default

This is the default driver which remaps to simple print(), warn() and die()
Perl calls.

=item Log::Agent::Driver::File

This driver redirects logs to files. Each logging channel may go to a dedicated
file.

=item Log::Agent::Driver::Silent

Silence all the logxxx() routines.

=item Log::Agent::Driver::Syslog

This driver redirects logs to the syslogd(8) daemon, which will then handle
the dispatching to various logfiles, based on its own configuration.

=back

=head1 INTERFACE

The following routines are B<deferred> and therefore need to be defined
by the heir:

=over

=item emit($channel, $priority, $logstring)

Emit the log entry held in $logstring, at priority $priority and through
the specfied $channel name. A trailing "\n" is to be added if needed, but the
$logstring should not already have one.

The $channel name is just a string, and it is up to the driver to map that
name to an output device using its own configuration information. The generic
logxxx() routines use only C<error>, C<output> or C<debug> for channel names.

The $priority entry is assumed to have passed through the map_pri() routine,
which by default returns an empty string (only the Log::Agent::Driver::Syslog
driver needs a priority, for now). Ignore if you don't need that, or redefine
map_pri().

The $logstring may not really be a plain string. It can actually be a
Log::Agent::Message object with an overloaded stringification routine, so
the illusion should be complete.

=item make

This is the creation routine. Its signature varies for each driver, naturally.

=item prefix_msg($str)

Prefix the log message string (a Log::Agent::Message object) with
driver-specific information (like the configured prefix, the PID of the
process, etc...).

Must return the prefixed string, either as a Log::Agent::Message object
or as a plain string. This means you may use normal string operations on the
$str variable and let the overloaded stringification perform its magic. Or
you may return the $str parameter without modification.

There is no default implementation here because this is too driver-specific
to choose one good default. And I like making things explicit sometimes.

=back

The following routines are implemented in terms of emit(), map_pri()
and prefix_msg(). The default implementation may need to be redefined for
performance or tuning reasons, but simply defining the two deferred routines
above should bring a reasonable behaviour nonetheless.

As an example, here is the default logdbg() implementation:

    sub logdbg {
        my $self = shift;
        my ($prio, $level, $str) = @_;
        $self->emit(
            'debug',
            $self->map_pri($prio, $level),
            $self->prefix_msg($str)
        );
    }

Yes, we do show the gory details in a manpage, but inheriting from a class
is not for the faint of heart, and requires getting acquainted with the
implementation, most of the time.

The order is not alphabetical here but by increased level of severity
(as expected, anyway):

=over

=item logdbg($priority, $level, $str)

Log debugging message to the C<debug> channel, at the specified priority/level,
obtained through a call to map_pri().

=item logtrc($priority, $level, $str)

Log message to the C<output> channel, at the specified priority/level,
obtained through a call to map_pri().

=item logsay($str)

Log message to the C<output> channel, at the C<notice> priority.

=item logwarn($str)

Log warning to the C<error> channel at the C<warning> priority.

=item logerr($str)

Log error to the C<error> channel at the C<error> priority.

=item logdie($str)

Log fatal error to the C<error> channel at the C<critical> priority
and then call die() with "$str\n" as argument.

=item logconfess($str)

Confess a fatal error. The error is logged to the C<error> channel at
the C<critical> priority and then Carp::confess() is called with "$str\n"
as argument.

=back

The following routine has a default implementation but may be redefined
for specific drivers:

=over

=item map_pri($priority, $level)

Converts a ("priority", level) tupple to a single priority token suitable
for emit(). By default, returns an empty string, which is OK only when
emit() does not care!

=back

The following routine is B<frozen>. There is no way in Perl to freeze a routine,
i.e. to explicitely forbid any redefinition, so this is an informal
notification:

=over

=item priority($priority)

This routine returns the proper priority for emit() for each of the
following strings: "critical", "error", "warning" and "notice", which are
the hardwired priority strings, as documented above.

It derives a logging level from the $priority given and then returns the
result of:

	map_pri($priority, $level);

Therefore, only map_pri() should be redefined.

=back

Finally, the following initialization routine is provided, to record the
C<prefix> attribute:

=over

=item _init($prefix)

Records the C<prefix> attribute.  Should be called in the constructor of
all the drivers that need to know about a prefix string to prepend to
logged messages.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Driver::Default(3), Log::Agent::Driver::File(3),
Log::Agent::Driver::Silent(3), Log::Agent::Driver::Syslog(3).

=cut
