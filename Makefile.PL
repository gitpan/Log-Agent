# $Id: Makefile.PL,v 1.4 2003/09/27 18:12:53 wendigo Exp $
#
#  Copyright (C) 1999 Raphael Manfredi
#  Copyright (C) 2003 Mark Rogaski, mrogaski@cpan.org; all rights reserved.
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Makefile.PL,v $
# Revision 1.4  2003/09/27 18:12:53  wendigo
# Removed unecessary prerequsites.
#
# Revision 1.3  2003/09/27 17:54:17  wendigo
# Fixed an simple CVS substitution problem.
#
# Revision 1.2  2003/09/27 16:29:17  wendigo
# Added metafile and disabled automatic metafile generation.
#
# Revision 1.1  2002/03/09 16:28:34  wendigo
# New maintainer
#
# Revision 0.2  2000/11/06 19:30:32  ram
# Baseline for second Alpha release.
#
# $EndLog$
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Log::Agent',
    VERSION_FROM => 'Agent.pm',
    PREREQ_PM => {
        'Tie::Array' => 0
    },
    ($] < 5.008_001 ? () : ( NO_META => 1 ))
);

