# --
# Copyright (C) 2018 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::GenericAgent::RedirectMail;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Ticket
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    $Param{To}   ||= $Param{New}->{To};
    $Param{From} ||= $Param{New}->{From};

    # check needed stuff
    for my $Needed (qw(TicketID To From) ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    if ( $Param{To} =~ m{<OTRS_TICKET_.+>} ) {
        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $Param{TicketID},
            DynamicFields => 1,
            UserID        => 1,
        );

        $Param{To} =~ s{<OTRS_TICKET_([^>]+)>}{$Ticket{$1}}g;
    }

    my %Article = $TicketObject->ArticleFirstArticle(
        TicketID => $Param{TicketID},
    );

    return 1 if $Article{ArticleType} !~ m{mail};

    $TicketObject->ArticleBounce(
        From      => $Param{From},
        To        => $Param{To},
        TicketID  => $Param{TicketID},
        ArticleID => $Article{ArticleID},
        UserID    => 1,
    );

    return 1;
}

1;
