#
# $Id: code.pl,v 0.1.1.1 2000/03/05 22:24:42 ram Exp $
#
#  Copyright (c) 1999, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: code.pl,v $
# Revision 0.1.1.1  2000/03/05 22:24:42  ram
# patch3: added ok()
#
# Revision 0.1  1999/12/07 21:09:44  ram
# Baseline for first alpha release.
#
# $EndLog$
#

sub ok {
	my ($num, $ok) = @_;
	print "not " unless $ok;
	print "ok $num\n";
}

sub contains {
	my ($file, $pattern) = @_;
	local *FILE;
	local $_;
	open(FILE, $file) || die "can't open $file: $!\n";
	my $found = 0;
	while (<FILE>) {
		if (/$pattern/) {
			$found = 1;
			last;
		}
	}
	close FILE;
	return $found;
}

1;

