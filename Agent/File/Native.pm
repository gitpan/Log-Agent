#
# $Id: Native.pm,v 0.1.1.1 2000/03/05 22:23:37 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#  
# HISTORY
# $Log: Native.pm,v $
# Revision 0.1.1.1  2000/03/05 22:23:37  ram
# patch3: created
#
# $EndLog$
#

use strict;

########################################################################
package Log::Agent::File::Native;

#
# A native Perl filehandle.
#
# I'm no longer using the IO::* hierarchy because it is useless.
#

#
# ->make
#
# Creation routine.
# Turns on autoflush as a side effect.
#
sub make {
	my $class = shift;
	my ($glob) = @_;
	select((select($glob), $| = 1)[0]);		# autoflush turned on
	return bless $glob, $class;
}

#
# ->print
#
# Print to file, propagates print() status.
#
sub print {
	my $glob = shift;
	return CORE::print $glob @_;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::File::Native - low-overhead IO::File

=head1 SYNOPSIS

 require Log::Agent::File::Native;

 my $fh = Log::Agent::File::Native->make(\*main::STDERR);

=head1 DESCRIPTION

This class is a stripped down implementation of IO::File, to avoid using
the IO::* hierarchy which does not work properly for my simple needs.

=over

=item make I<glob>

This is the creation routine. Encapsulates the I<glob> reference so that
we can use object-oriented calls on it.

=item print I<args>

Prints I<args> to the file.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::File::Rotate(3), Log::Agent::Driver::File(3).

=cut
