# Detail for SignaturePlugin
#

package Foswiki::Plugins::SignaturePlugin::Signature;

# Always use strict to enforce variable scoping
use strict;
use Foswiki::Attrs;

sub handleSignature {
    my ( $cnt, $attr ) = @_;
    my $session = $Foswiki::Plugins::SESSION;

    $attr = new Foswiki::Attrs($attr);
    my $lbl = Foswiki::Func::getPreferencesValue(
        "\U$Foswiki::Plugins::SignaturePlugin::pluginName\E_SIGNATURELABEL")
      || 'Sign';

    my $name = '';
    $name = '_(' . $attr->{name} . ')_ &nbsp;' if $attr->{name};

    return
        "<noautolink> $name </noautolink><form action=\""
      . &Foswiki::Func::getScriptUrl( 'SignaturePlugin', 'sign', 'rest' )
      . "\" /><input type=\"hidden\" name=\"nr\" value=\"$cnt\" /><input type=\"submit\" value=\"$lbl\" /><input type=\"hidden\" name=\"topic\" value=\"$session->{webName}.$session->{topicName}\" /></form>";

}

sub sign {
    my $session = shift;
    $Foswiki::Plugins::SESSION = $session;
    my $query = $session->{cgiQuery};
    return unless ($query);

    my $cnt = $query->param('nr');

    my $webName = $session->{webName};
    my $topic   = $session->{topicName};
    my $user    = $session->{user};

    return
      unless (
        &doEnableEdit( $webName, $topic, $user, $query, 'editTableRow' ) );

    my ( $meta, $text ) = &Foswiki::Func::readTopic( $webName, $topic );
    $text =~ s/%SIGNATURE(?:{(.*)})?%/&replaceSignature($cnt--, $user, $1)/geo;

    my $error = &Foswiki::Func::saveTopicText( $webName, $topic, $text, 1 );
    Foswiki::Func::setTopicEditLock( $webName, $topic, 0 );    # unlock Topic
    if ($error) {
        Foswiki::Func::redirectCgiQuery( $query, $error );
        return 0;
    }
    else {

        # and finally display topic
        Foswiki::Func::redirectCgiQuery( $query,
            &Foswiki::Func::getViewUrl( $webName, $topic ) );
    }

}

sub replaceSignature {
    my ( $dont, $user, $attr ) = @_;

    return ( ($attr) ? "%SIGNATURE{$attr}%" : '%SIGNATURE%' ) if $dont;

    $attr = new Foswiki::Attrs($attr);

    my $wuser = Foswiki::Func::getWikiName($user);
    my %list = map { s/.*\.//; $_ => 1 } split( /[, ]+/, $attr->{name} );
    foreach my $n (%list) {
        if (   Foswiki::Func::isGroup($n)
            || Foswiki::Func::isGroupMember( $n, $wuser ) )
        {
            $list{$wuser} = 1;
        }
    }

    unless ( !$attr->{name} || $list{$wuser} ) {
        use Foswiki::OopsException;
        my $session = $Foswiki::Plugins::SESSION;
        Foswiki::Func::setTopicEditLock( $session->{webName},
            $session->{topicName}, 0 );    # unlock Topic
        throw Foswiki::OopsException(
            'generic',
            web    => $session->{webName},
            topic  => $session->{topicName},
            params => [
                'Attention',
                $wuser . ' is not permitted to sign here.',
                'Please go back in your browser and sign at the correct spot.',
                ' '
            ]
        );
        exit;
    }

    my $fmt = $attr->{format}
      || Foswiki::Func::getPreferencesValue(
        "\U$Foswiki::Plugins::SignaturePlugin::pluginName\E_SIGNATUREFORMAT")
      || '$wikiusername - $date';

    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my ( $d, $m, $y ) = (localtime)[ 3, 4, 5 ];
    $y += 1900;
    my $ourDate = sprintf( '%02d %s %d', $d, $months[$m], $y );

    $fmt =~ s/\$quot/\"/go;
    $fmt =~ s/\$wikiusername/&Foswiki::Func::getWikiUserName($user)/geo;
    $fmt =~ s/\$wikiname/&Foswiki::Func::getWikiName($user)/geo;
    $fmt =~ s/\$username/$user/geo;
    $fmt =~ s/\$date/$ourDate/geo;

    return $fmt;

}

sub doEnableEdit {
    my ( $theWeb, $theTopic, $user, $query ) = @_;

    if (
        !&Foswiki::Func::checkAccessPermission(
            "change", $user, "", $theTopic, $theWeb
        )
      )
    {

        # user does not have permission to change the topic
        throw Foswiki::OopsException(
            'accessdenied',
            def   => 'topic_access',
            web   => $_[2],
            topic => $_[1],
            params =>
              [ 'Edit topic', 'You are not permitted to edit this topic' ]
        );
        return 0;
    }

    my ( $oopsUrl, $lockUser ) =
      &Foswiki::Func::checkTopicEditLock( $theWeb, $theTopic, 'edit' );
    if ( $lockUser && !( $lockUser eq $user ) ) {

        # warn user that other person is editing this topic
        &Foswiki::Func::redirectCgiQuery( $query, $oopsUrl );
        return 0;
    }
    Foswiki::Func::setTopicEditLock( $theWeb, $theTopic, 1 );

    return 1;

}

1;
