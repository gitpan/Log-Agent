#
# $Id: File.pm,v 0.1 1999/12/07 21:09:44 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: File.pm,v $
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

use strict;
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::File;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

use IO::Handle;
use Fcntl;

#
# ->make			-- defined
#
# Creation routine.
#
# Attributes (and switches that set them):
#
# prefix		the application name
# duperr		whether to duplicate "error" channels to "output"
# stampfmt		stamping format ("syslog", "date", "own", "none") or closure
# showpid		whether to show pid after prefix in []
# channels		where each channel ("error", "output", "debug") goes
# magic_open	flag to tell whether ">>file" or "|proc" are allowed filenames
#
# Additional switches:
#
# file			sole channel, implies -duperr = 0 and supersedes -channels
#
# Other attributes:
#
# channel_fds	file descriptors for opened channels
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;
	my $prefix;
	my $file;

	my %set = (
		-prefix		=> \$prefix,				# Handled by parent via _init
		-duperr		=> \$self->{'duperr'},
		-channels	=> \$self->{'channels'},
		-stampfmt	=> \$self->{'stampfmt'},
		-showpid	=> \$self->{'showpid'},
		-magic_open	=> \$self->{'magic_open'},
		-file		=> \$file,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		$$vset = $val;
	}

	#
	# If -file was used, it supersedes -duperr and -channels
	#

	if (defined $file && length $file) {
		$self->{'channels'} = {
			'debug'		=> $file,
			'output'	=> $file,
			'error'		=> $file,
		};
		$self->{'duperr'} = 0;
	}

	#
	# Initialize proper time-stamping routine.
	#

	$self->{'stampfmt'} = $self->stamping_fn($self->stampfmt)
		unless ref $self->stampfmt eq 'CODE';

	$self->_init($prefix);
	$self->{'channels'} = {} unless $self->channels;	# No defined channel
	$self->{'channel_fds'} = {};						# No opened files
	return $self;
}

#
# Attribute access
#

sub duperr		{ $_[0]->{'duperr'} }
sub channels	{ $_[0]->{'channels'} }
sub channel_fds	{ $_[0]->{'channel_fds'} }
sub stampfmt	{ $_[0]->{'stampfmt'} }
sub showpid		{ $_[0]->{'showpid'} }
sub magic_open	{ $_[0]->{'magic_open'} }

#
# ->prefix_msg		-- defined
#
# Prepend stamping and "prefix: " to the error string, if needed.
# Leading char is upper-cased if neither prefix nor pid are present.
#
sub prefix_msg {
	my $self = shift;
	my ($str) = @_;
	my $prefix = $self->prefix;
	$prefix = '' unless defined $prefix;
	if ($self->showpid) {
		if ($prefix eq '') {
			$prefix = $$;
		} else {
			$prefix .= "[$$]";
		}
	} elsif ($prefix eq '') {
		$str = ucfirst($str);
	}
	my $stamp = &{$self->stampfmt};
	return
		($stamp eq '' ? '' : "$stamp ") . 
		($prefix eq '' ? '' : "$prefix: ") .
		$str;
}

#
# ->emit			-- defined
#
sub emit {
	my $self = shift;
	my ($channel, $priority, $logstring) = @_;
	local $\ = undef;
	my $fd = $self->channel_fds->{$channel};
	$fd = $self->open_channel($channel) unless $fd;
	return unless $fd;
	print $fd $logstring, "\n";
}

#
# ->open_channel
#
# Open given channel according to the configured channel description and
# return the opened file descriptor.
# If no channel was defined, use 'error' or STDERR.
#
sub open_channel {
	my $self = shift;
	my ($channel) = @_;
	my $filename = $self->channels->{$channel};

	#
	# No channel defined, use 'error', or revert to STDERR
	#

	$filename = $self->channels->{'error'} unless length $filename;

	unless (length $filename) {
		select((select(main::STDERR), $| = 1)[0]);
		return $self->channel_fds->{$channel} = \*main::STDERR;
	}

	my $h = IO::Handle->new;

	#
	# They may use ">file" or "|proc" as channel files if -magic_open
	#

	if ($filename =~ /^\s*[>|]/ && $self->magic_open) {
		open($h, $filename) || return undef;
	} else {
		sysopen($h, $filename, O_CREAT|O_APPEND|O_WRONLY) || return undef;
	}

	select((select($h), $| = 1)[0]);
	return $self->channel_fds->{$channel} = $h;
}

#
# ->emit_output
#
# Force error message to the regular 'output' channel with a specified tag.
#
sub emit_output {
	my $self = shift;
	my ($priority, $tag, $str) = @_;
	my $cstr = $str->clone;				# We're prepending tag on a copy
	$cstr->prepend("$tag: ");
	$self->emit('output',
		$self->priority($priority),
		$self->prefix_msg($cstr));
}

###
### Redefined routines to handle duperr
###

#
# ->logconfess
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with FATAL.
#
sub logconfess {
	my $self = shift;
	my ($str) = @_;
	$self->emit_output('critical', "FATAL", $str) if $self->duperr;
	$self->SUPER::logconfess($str);
}

#
# ->logdie
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with FATAL.
#
sub logdie {
	my $self = shift;
	my ($str) = @_;
	$self->emit_output('critical', "FATAL", $str) if $self->duperr;
	$self->SUPER::logdie($str);
}

#
# ->logerr
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with ERROR.
#
sub logerr {
	my $self = shift;
	my ($str) = @_;
	$self->emit_output('error', "ERROR", $str) if $self->duperr;
	$self->SUPER::logerr($str);
}

#
# ->logwarn
#
# When `duperr' is true, emit message on the 'output' channel prefixed
# with ERROR.
#
sub logwarn {
	my $self = shift;
	my ($str) = @_;
	$self->emit_output('warning', "WARNING", $str) if $self->duperr;
	$self->SUPER::logwarn($str);
}

1;	# for require

=head1 NAME

Log::Agent::Driver::File - file logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::File;

 my $driver = Log::Agent::Driver::File->make(
     -prefix     => "prefix",
     -duperr     => 1,
     -stampfmt   => "own",
     -showpid    => 1,
     -magic_open => 0,
     -channels   => {
        'error'   => '/tmp/output.err',
        'output'  => 'log.out',
        'debug'   => '../appli.debug',
     },
 );
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The file logging driver redirects logxxx() operations to specified files,
one per channel usually (but channels may go to the same file).

The creation routine make() takes the following arguments:

=over

=item C<-channels> => I<hash ref>

Specifies where channels go. The supplied hash maps channel names
(C<error>, C<output> and C<debug>) to filenames. When C<-magic_open> is
set to true, filenames are allowed magic processing via perl's open(), so
this allows things like:

    -channels => {
        'error'   => '>&FILE',
        'output'  => '>newlog',   # recreate each time, don't append
        'debug'  => '|mailx -s whatever user',
    }

If a channel (e.g. 'output') is not specified, it will go to the 'error'
channel, and if that one is not specified either, it will go to STDERR instead.

=item C<-duperr> => I<flag>

When true, all messages normally sent to the C<error> channel are also
copied to the C<output> channel with a prefixing made to clearly mark
them as such: "FATAL: " for logdie() and logconfess(), "ERROR: " for logerr()
and "WARNING: " for logwarn().

Default is false.

=item C<-file> => I<file>

This switch supersedes both C<-duperr> and C<-channels> by defining a
single file for all the channels.

=item C<-magic_open> => I<flag>

When true, channel filenames beginning with '>' or '|' are opened using
Perl's open(). Otherwise, sysopen() is used, in append mode.

Default is false.

=item C<-prefix> => I<prefix>

The application prefix string to prepend to messages.

=item C<-showpid> => I<flag>

If set to true, the PID of the process will be appended within square
brackets after the prefix, to all messages.

Default is false.

=item C<-stampfmt> => (I<name> | I<CODE>)

Specifies the time stamp format to use. By default, my "own" format is used.
The following formats are available:

    date      "[Fri Oct 22 16:23:10 1999]"
    none
    own       "99/10/24 09:43:49"
    syslog    "Oct 27 21:09:33".

You may also specify a CODE ref: that routine will be called every time
we need to compute a time stamp. It should not expect any parameter, and
should return a string.

=back

=head1 CHANNELS

All the channels go to the specified files. If a channel is not configured,
it is redirected to 'error', or STDERR if no 'error' channel was configured
either.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3).

=cut
