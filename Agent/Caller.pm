#
# $Id: Caller.pm,v 0.1 1999/12/07 21:09:44 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Caller.pm,v $
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;

########################################################################
package Log::Agent::Caller;

#
# ->make
#
# Creation routine.
#
# Calling arguments: a hash table list.
#
# The keyed argument list may contain:
#	-OFFSET		value for the offset attribute [NOT DOCUMENTED]
#	-INFO		string of keywords like "package filename line subroutine"
#	-FORMAT		formatting instructions, like "%s:%d", used along with -INFO
#	-POSTFIX	whether to postfix log message or prefix it.
#   -DISPLAY    a string like '($package::$subroutine/$line)', supersedes -INFO
#
# Attributes:
#	indices		listref of indices to select in the caller() array
#	offset		how many stack frames are between us and the caller we trace
#	format		how to format extracted caller() info
#	postfix		true if info to append to logged string
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;

	$self->{'offset'} = 0;
	$self->{'postfix'} = 0;

	my ($info, $format);

	my %set = (
		-offset		=> \$self->{'offset'},
		-info		=> \$info,
		-format		=> \$self->{'format'},
		-postfix	=> \$self->{'postfix'},
		-display	=> \$self->{'display'},
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		next unless ref $vset;
		$$vset = $val;
	}

	return $self if $self->display;		# A display string takes precedence

	#
	# pre-process info to compute the indices
	#

	my $i = 0;
	my %indices = map { $_ => $i++ } qw(pac fil lin sub);	# abbrevs
	my @indices = ();

	foreach my $token (split(' ', $info)) {
		my $abbr = substr($token, 0, 3);
		push(@indices, $indices{$abbr}) if exists $indices{$abbr};
	}

	$self->{'indices'} = \@indices;

	return $self;
}

#
# Attribute access
#

sub offset		{ $_[0]->{'offset'} }
sub indices		{ $_[0]->{'indices'} }
sub format		{ $_[0]->{'format'} }
sub display		{ $_[0]->{'display'} }
sub postfix		{ $_[0]->{'postfix'} }

#
# ->insert
#
# Merge caller string into the log message, according to our configuration.
#
sub insert {
	my $self = shift;
	my ($str) = @_;			# A Log::Agent::Message object

	#
	# The following code:
	#
	#	sub foo {
	#		my ($pack, $file, $line, $sub) = caller(0);
	#		print "excuting $sub called at $file/$line in $pack";
	#	}
	#
	# will report who called us, except that $sub will be US, not our CALLER!
	# This is an "anomaly" somehow, and therefore to get the routine name
	# that called us, we need to move one frame above the ->offset value.
	#

	my @caller = caller($self->offset);
	$caller[3] = (caller($self->offset + 1))[3];	# Anomaly in caller()!
	my ($package, $filename, $line, $subroutine) = @caller;

	#
	# If there is a display, it takes precedence and is formatted accordingly,
	# with limited variable substitution. The variables that are recognied
	# are:
	#
	#		$package or $pack		package name of caller
	#		$filename or $file		filename of caller
	#		$line					line number of caller
	#		$subroutine or $sub		routine name of caller
	#
	# Otherwise, the necessary information is gathered from the caller()
	# output, and formatted via sprintf, along with the special %a macro
	# which stands for all the information, separated by ':'.
	#
	# NB: The default format is "[%a]" for postfixed info, "(%a)" otherwise.
	#

	my $display = $self->display;
	if ($display) {
		$display =~ s/\$pack(?:age)?/$package/g;
		$display =~ s/\$file(?:name)?/$filename/g;
		$display =~ s/\$line/$line/g;
		$display =~ s/\$sub(?:routine)?/$subroutine/g;
	} else {
		my @show = map { $caller[$_] } @{$self->indices};
		my $format = $self->format || ($self->postfix ? "[%a]" : "(%a)");
		$format =~ s/((?<!%)(?:%%)*)%a/join(':', @show)/ge;
		$display = sprintf $format, @show;
	}

	#
	# Merge into the Log::Agent::Message object string.
	#

	if ($self->postfix) {
		$str->append(" $display");
	} else {
		$str->prepend("$display ");
	}

	return $str;
}

=head1 NAME

Log::Agent::Caller - formats caller information

=head1 SYNOPSIS

 Not intended to be used directly

=head1 DESCRIPTION

This class handles caller information for Log::Agent services and is not
meant to be used directly.

This manpage therefore only documents the creation routine parameters
that can be specified at the Log::Agent level via the C<-caller> switch
in the logconfig() routine.

=head1 CALLER INFORMATION ENTITIES

This class knows about four entities: I<package>, I<filename>, I<line>
and I<subroutine>, which are to be understood within the context of the
Log::Agent routine being called (e.g. a logwarn() routine), namely:

=over

=item package

This is the package name where the call to the logwarn() routine was made.
It can be specified as "pack" for short, or spelled out completely.

=item filename

This is the file where the call to the logwarn() routine was made.
It can be specified as "file" for short, or spelled out completely.

=item line

This is the line number where the call to the logwarn() routine was made,
in file I<filename>. The name is short enough to be spelled out completely.

=item subroutine

This is the subroutine where the call to the logwarn() routine was made.
If the call is made outside a subroutine, this will be empty.
The name is long enough to warrant the "sub" abbreviation if you don't wish
to spell it out fully.

=back

=head1 CREATION ROUTINE PARAMETERS

The purpose of those parameters is to define how caller information entities
(as defined by the previous section) will be formatted within the log message.

=over

=item C<-display> => I<string>

Specifies a string with minimal variable substitution: only the caller
information entities specified above, or their abbreviation, will be
interpolated. For instance:

	-display => '($package::$sub/$line)'

Don't forget to use simple quotes to avoid having Perl interpolate those
as variables, or escape their leading C<$> sign otherwise. Using this
convention was deemed to more readable (and natural in Perl)
than SGML entities such as "&pack;".

Using this switch supersedes the C<-info> and <-format> switches.

=item C<-format> => I<printf format>

Formatting instructions for the caller information entities
listed by the C<-info> switch. For instance:

    -format => "%s:%4d"

if you have specified two entities in C<-info>.

The special formatting macro C<%a> stands for all the entities specified
by C<-info> and is rendered by a string where values are separated by ":".

=item C<-info> => I<"space separated list of parameters">

Specifies a list of caller information entities that are to be formated
using the C<-format> specification. For instance:

	-info => "pack sub line"

would only report those three entites.

=item C<-postfix> => I<flag>

Whether the string resulting from the formatting of the caller information
entities should be appended to the regular log message or not
(i.e. prepended, which is the default).

Separation from the remaining of the log message is a single space.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Message(3).

1;
