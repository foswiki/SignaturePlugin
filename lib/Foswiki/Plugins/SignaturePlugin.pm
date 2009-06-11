# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2006 Motorola, thomas.weigert@motorola.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# For licensing info read LICENSE file in the TWiki root.

package Foswiki::Plugins::SignaturePlugin;

# Always use strict to enforce variable scoping
use strict;

# $VERSION is referred to by TWiki, and is the only global variable that
# *must* exist in this package
use vars qw( $VERSION $RELEASE $pluginName );

# This should always be $Rev$ so that TWiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
$VERSION = '$Rev$';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
$RELEASE = 'Foswiki';

# Name of this Plugin, only used in this module
$pluginName = 'SignaturePlugin';

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    if ( $Foswiki::Plugins::VERSION < 1.1 ) {
        Foswiki::Func::writeWarning(
            "This version of $pluginName works only with Foswiki 1.0 and greater.");
        return 0;
    }

    Foswiki::Func::registerRESTHandler( 'sign', \&sign );
    return 1;

}

sub preRenderingHandler {
### my ( $text ) = @_;   # do not uncomment, use $_[0], $_[1] instead

    # This handler is called by getRenderedVersion just before the line loop
    # Only bother with this plugin if viewing (i.e. not searching, etc)
    return unless ( $0 =~ m/view|viewauth|render/o );

    my $cnt;
    $_[0] =~ s/%SIGNATURE(?:{(.*)})?%/&handleSignature($cnt++, $1)/geo;

}

sub handleSignature {
    require Foswiki::Plugins::SignaturePlugin::Signature;
    return Foswiki::Plugins::SignaturePlugin::Signature::handleSignature(@_);
}

sub sign {
    require Foswiki::Plugins::SignaturePlugin::Signature;
    Foswiki::Plugins::SignaturePlugin::Signature::sign(@_);
}

1;
