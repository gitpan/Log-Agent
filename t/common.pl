###########################################################################
# $Id: common.pl,v 1.2 2002/05/12 08:55:53 wendigo Exp $
###########################################################################
#
# common.pl
#
# RCS Revision: $Revision: 1.2 $
# Date: $Date: 2002/05/12 08:55:53 $
#
# Copyright (C) 1999 Raphael Manfredi.
# Copyright (C) 2002 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
# $Log: common.pl,v $
# Revision 1.2  2002/05/12 08:55:53  wendigo
# added precompilation of regexp in contains()
#
# Revision 1.1  2002/02/23 06:26:10  wendigo
# Initial revision
#
#
###########################################################################

sub contains ($$) {
    my ($file, $pattern) = @_;
    $pattern = qr{$pattern};
    local *FILE;
    local $_;
    open(FILE, $file) || die "can't open $file: $!\n";
    my $found = 0;
    my $line = 0;
    while (<FILE>) {
        $line++;
        if (/$pattern/) {
            $found = 1;
            last;
        }
    }
    close FILE;
    return $found ? $line : 0;
}

sub perm_ok ($$) {
    #
    # Given a fileame and target permissions, checks if the file
    # was created with the correct permissions.
    #
    my($file, $target) = @_;

    $target &= ~ umask;         # account for user mask 
    my $mode = (stat $file)[2]; # find the current mode
    $mode &= 0777;              # we only care about UGO

    return $mode == $target;
}

1;

