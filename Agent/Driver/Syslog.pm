#
# $Id: Syslog.pm,v 0.1.1.1 2000/03/05 22:23:32 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Syslog.pm,v $
# Revision 0.1.1.1  2000/03/05 22:23:32  ram
# patch3: added end marker before pod
#
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::Syslog;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

use Sys::Syslog qw(:DEFAULT setlogsock);

#
# ->make			-- defined
#
# Creation routine.
#
# Attributes (and switches that set them):
#
# prefix		the application name
# facility		the syslog facility name to use ("auth", "daemon", etc...)
# showpid		whether to show pid
# socktype		socket type ('unix' or 'inet')
# logopt		list of openlog() options: 'ndelay', 'cons' or 'nowait'
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;
	my $prefix;

	my %set = (
		-prefix		=> \$prefix,				# Handled by parent via _init
		-facility	=> \$self->{'facility'},
		-showpid	=> \$self->{'showpid'},
		-socktype	=> \$self->{'socktype'},
		-logopt		=> \$self->{'logopt'},
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		$$vset = $val;
	}

	$self->{'logopt'} =~ s/\bpid\b//g;			# Must use showpid => 1
	$self->{'logopt'} .= ' pid' if $self->showpid;

	$self->_init($prefix);
	return $self;
}

#
# Attribute access
#

sub facility	{ $_[0]->{'facility'} || 'user' }
sub showpid		{ $_[0]->{'showpid'} }
sub socktype	{ $_[0]->{'socktype'} }
sub logopt		{ $_[0]->{'logopt'} }
sub connected	{ $_[0]->{'connected'} }

#
# ->connect
#
# Connect to syslogd.
#
sub connect {
	my $self = shift;
	setlogsock $self->socktype if $self->socktype;
	openlog $self->prefix, $self->logopt, $self->facility;
	$self->{'connected'}++;
}

#
# ->disconnect
#
# Disconnect from syslogd.
#
sub disconnect {
	my $self = shift;
	return unless $self->connected;
	closelog;
	$self->{'connected'} = 0;
}

#
# ->prefix_msg		-- defined
#
# NOP -- syslog will handle this
#
sub prefix_msg {
	my $self = shift;
	return $_[0];
}

my %syslog_pri = (
	'em' => 'emerg',
	'al' => 'alert',
	'cr' => 'crit',
	'er' => 'err',
	'wa' => 'warning',
	'no' => 'notice',
	'in' => 'info',
	'de' => 'debug'
);

#
# ->map_pri			-- redefined
#
# Levels ignored, only priorities matter.
#
sub map_pri {
	my $self = shift;
	my ($priority, $level) = @_;
	return $syslog_pri{lc(substr($priority, 0, 2))} || 'debug';
}

#
# ->emit			-- defined
#
# $channel is ignored
#
sub emit {
	my $self = shift;
	my ($channel, $priority, $logstring) = @_;
	local $\ = undef;
	$self->connect unless $self->connected;
	syslog $priority, "%s", $logstring;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Driver::Syslog - syslog logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::Syslog;

 my $driver = Log::Agent::Driver::Syslog->make(
     -prefix     => prefix,
     -facility   => "user",
     -showpid    => 1,
     -socktype   => "unix",
     -logopt     => "ndelay",
 );
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The syslog logging driver delegates logxxx() operations to syslog() via
the Sys::Syslog(3) interface.

The creation routine make() takes the following switches:

=over

=item C<-facility> => I<facility>

Tell syslog() which facility to use (e.g. "user", "auth", "daemon").
Unlike the Sys::Syslog(3) interface, the facility is set once and for all:
every logging message will use the same facility.

If you wish to log something to "auth" for instance, then do so via
Sys::Syslog directly: there is no guarantee that the application will configure
its Log::Agent to use syslog anyway!

=item C<-logopt> => I<syslog options>

Specifies logging options, under the form of a string containing zero or
more of the words I<ndelay>, I<cons> or I<nowait>.

=item C<-prefix> => I<prefix>

The I<prefix> here is syslog's identification string.

=item C<-showpid> => I<flag>

Set to true to have the PID of the process logged. It is false by default.

=item C<-socktype> => (I<unix> | I<inet>)

Specifies the logging socket type to use. The default behaviour is to
use Sys:Syslog's default.

=back

=head1 CHANNELS

All the channels go to syslog(), of course.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3).

=cut
