#
# $Id: Formatting.pm,v 0.2 2000/11/06 19:30:33 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Formatting.pm,v $
# Revision 0.2  2000/11/06 19:30:33  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

use strict;
require Exporter;

########################################################################
package Log::Agent::Formatting;

use vars qw(@ISA @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT_OK = qw(format_args caller_format_args);

require Log::Agent::Message;

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
if ($] >= 5.005) { eval q{				# if VERSION >= 5.005

# 5.005 and later version grok /(?<!)/
sub format_args {
	my $ary = shift;
	my $fmt = shift @$ary;
	$fmt =~ s/((?<!%)(?:%%)*)%m/$!/g;
	my $str = Log::Agent::Message->make(@$ary ? sprintf($fmt, @$ary) : $fmt);
	return $str;
}

}} else { eval q{						# else /* VERSION < 5.005 */

# pre-5.005 does not grok /(?<!)/
sub format_args {
	my $ary = shift;
	my $fmt = shift @$ary;
	$fmt =~ s/%%/\01/g;
	$fmt =~ s/%m/$!/g;
	$fmt =~ s/\01/%%/g;
	my $str = Log::Agent::Message->make(@$ary ? sprintf($fmt, @$ary) : $fmt);
	return $str;
}

}}										# endif /* VERSION >= 5.005 */

#
# caller_format_args
#
# Same as format_args, but first argument yields a caller object.
# If defined, tell it to insert its information within the formatted message.
#
sub caller_format_args {
	my $caller = shift;
	my $str = &format_args;
	$caller->insert($str) if $caller;
	return $str;
}

1;

