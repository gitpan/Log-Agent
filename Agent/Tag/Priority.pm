#
# $Id: Priority.pm,v 0.2.1.1 2001/03/13 18:45:20 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Priority.pm,v $
# Revision 0.2.1.1  2001/03/13 18:45:20  ram
# patch2: created
#
# Revision 0.2  2000/11/06 19:30:32  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

use strict;

########################################################################
package Log::Agent::Tag::Priority;

require Log::Agent::Tag::String;
use vars qw(@ISA);
@ISA = qw(Log::Agent::Tag::String);

#
# ->make
#
# Creation routine.
#
# Calling arguments: a hash table list.
#
# The keyed argument list may contain:
#	-POSTFIX	whether to postfix log message or prefix it.
#   -SEPARATOR  separator string to use between tag and message
#   -DISPLAY    a string like '[$priority:$level])'
#   -PRIORITY   the log priority string, e.g. "warning".
#   -LEVEL      the log level value, e.g. 4.
#
# Attributes:
#   none, besides the inherited ones
#
sub make {
	my $type = shift;
	my (%args) = @_;
	my $separator = " ";
	my $postfix = 0;
	my ($display, $priority, $level);

	my %set = (
		-display	=> \$display,
		-postfix	=> \$postfix,
		-separator	=> \$separator,
		-priority	=> \$priority,
		-level		=> \$level,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		next unless ref $vset;
		$$vset = $val;
	}

	#
	# Format according to -display specs.
	#
	# Since priority and level are fixed for this object, the resulting
	# string need only be computed once, i.e. now.
	#
	# The following variables are recognized:
	#
	#		$priority	 			priority name (e.g. "warning")
	#		$level					logging level
	#
	# We recognize both $level and ${level}.
	#

	$display =~ s/\$priority\b/$priority/g;
	$display =~ s/\${priority}/$priority/g;
	$display =~ s/\$level\b/$level/g;
	$display =~ s/\${level}/$level/g;

	#
	# Now create the constant tag string.
	#

	my $self = Log::Agent::Tag::String->make(
		-name		=> "priority",
		-value		=> $display,
		-postfix	=> $postfix,
		-separator	=> $separator,
	);

	return bless $self, $type;		# re-blessed in our package
}

1;			# for "require"
__END__

=head1 NAME

Log::Agent::Tag::Priority - a log priority tag string

=head1 SYNOPSIS

 Not intended to be used directly
 Inherits from Log::Agent::Tag.

=head1 DESCRIPTION

This class represents a log priority tag string.

=head1 CREATION ROUTINE PARAMETERS

The following parameters are defined, in alphabetical order:

=over

=item C<-name> => I<name>

The name of this tag.  Currently unused.

=item C<-postfix> => I<flag>

Whether tag should be placed after or before the log message.
By default, it is prepended to the log message, i.e. this parameter is false.

=item C<-separator> => I<string>

The separation string between the tag and the log message.
A single space by default.

=item C<-value> => I<string>

The tag's value.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Tag(3), Log::Agent::Message(3).

=cut

