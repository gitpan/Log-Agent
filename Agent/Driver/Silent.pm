#
# $Id: Silent.pm,v 0.1.1.3 2000/10/01 19:53:23 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Silent.pm,v $
# Revision 0.1.1.3  2000/10/01 19:53:23  ram
# patch8: conforms to changed driver interface
#
# Revision 0.1.1.2  2000/06/20 21:25:25  ram
# patch5: added empty logwrite() and new logcroak()
#
# Revision 0.1.1.1  2000/03/05 22:23:29  ram
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
package Log::Agent::Driver::Silent;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

#
# ->make			-- defined
#
# Creation routine.
#
sub make {
	my $self = bless {}, shift;
	return $self;
}

#
# NOP routines.
#

sub prefix_msg {}
sub emit {}
sub channel_eq { 1 }

#
# In theory, we could live with the above NOP ops and the logxxx()
# routines would not do anything. Let's redefine them though...
#

sub logerr {}
sub logwarn {}
sub logsay {}
sub logwrite {}
sub logxcarp {}

#
# Those need minimal processing.
# We explicitely stringify the string argument (uses overloaded "" method)
#

sub logconfess { require Carp; Carp::confess("$_[1]"); }
sub logdie     { die "$_[0]\n"; }

#
# ->logxcroak		-- redefined
#
# Handle the offset parameter correctly
#
sub logxcroak  {
	my $self = shift;
	my ($offset, $str) = @_;
	require Carp;
	my $msg = $self->carpmess($offset, $str, \&Carp::shortmess);
	die "$msg\n";
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Driver::Silent - silent logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::Silent;

 my $driver = Log::Agent::Driver::Silent->make();
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The silent logging driver remaps most of the logxxx() operations to NOPs.
Only logconfess() and logdie() respectively call Carp::confess() and die().

=head1 CHANNELS

All the channels go to /dev/null, so to speak.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3).

=cut
