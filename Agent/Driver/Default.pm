#
# $Id: Default.pm,v 0.1 1999/12/07 21:09:44 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Default.pm,v $
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::Default;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

#
# ->make			-- defined
#
# Creation routine.
#
sub make {
	my $self = bless {}, shift;
	my ($prefix) = @_;
	$self->_init($prefix);
	my $orig = select(main::STDOUT); $| = 1;	# Autoflush
	select(main::STDERR); $| = 1;
	select($orig);
	return $self;
}

#
# ->prefix_msg		-- defined
#
# Prepend "prefix: " to the error string, or nothing if no prefix, in which
# case we capitalize the very first letter of the string.
#
sub prefix_msg {
	my $self = shift;
	my ($str) = @_;
	my $prefix = $self->prefix;
	return ucfirst($str) if !defined($prefix) || $prefix eq '';
	return "$prefix: " . $str;
}

#
# ->emit			-- defined
#
sub emit {
	my $self = shift;
	my ($channel, $priority, $logstring) = @_;
	local $\ = undef;
	my $fd = ($channel eq 'error') ? \*main::STDERR : \*main::STDOUT;
	print $fd "$logstring\n";
}

#
# ->logconfess		-- redefined
#
# Fatal error, with stack trace
#
sub logconfess {
	my $self = shift;
	my ($str) = @_;
	require Carp;
	Carp::confess($self->prefix_msg("$str\n"));
}

#
# ->logdie			-- redefined
#
# Fatal error
#
sub logdie {
	my $self = shift;
	my ($str) = @_;
	die $self->prefix_msg("$str\n");
}

#
# ->logerr			-- redefined
#
# Signal error on stderr
#
sub logerr {
	my $self = shift;
	my ($str) = @_;
	warn $self->prefix_msg("$str\n");
}

#
# ->logwarn			-- redefined
#
# Warn, with "WARNING" clearly emphasized
#
sub logwarn {
	my $self = shift;
	my ($str) = @_;
	$str->prepend("WARNING: ");
	warn $self->prefix_msg("$str\n");
}

1;	# for require

=head1 NAME

Log::Agent::Driver::Default - default logging driver for Log::Agent

=head1 SYNOPSIS

 # Implicit use
 use Log::Agent;
 logconfig(-prefix => "prefix");   # optional

 # Explicit use
 use Log::Agent;
 require Log::Agent::Driver::Default;

 my $driver = Log::Agent::Driver::Default->make("prefix");
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The default logging driver remaps the logxxx() operations to their
default Perl counterpart. For instance, logerr() will issue a warn()
and logwarn() will call warn() with a clear "WARNING: " emphasis
(to distinguish between the two calls).

The only routine of interest here is the creation routine:

=over

=item make($prefix)

Create a Log::Agent::Driver::Default driver whose prefix string will be
$prefix. When no prefix is configured, the first letter of each logged
string will be uppercased.

=head1 CHANNELS

The C<error> channel goes to STDERR, the C<output> and C<debug> channels
to STDOUT.

=head1 BUGS

If logdie() is used within an eval(), the string you will get in $@ will
be prefixed. It's not really a bug, simply that wrapping a code into
eval() and parsing $@ is poor's man exception handling which shows its
limit here: since the programmer using logdie() cannot foresee which
driver will be used, the returned string cannot be determined precisely.
Morality: use die() if you mean it, and document the string as an exception.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3).

=cut
