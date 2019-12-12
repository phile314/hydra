package Hydra::Plugin::PhabricatorDiffs;

use strict;
use parent 'Hydra::Plugin';
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Hydra::Helper::CatalystUtils;
use File::Temp;
use POSIX qw(strftime);

sub supportedInputTypes {
    my ($self, $inputTypes) = @_;
    $inputTypes->{'phabdiff'} = 'Phabricator Diff Revision';
}


sub fetchInput {
    my ($self, $type, $name, $value, $project, $jobset) = @_;
    return undef if $type ne "phabdiff";


    (my $phabUrl, my $diffId) = split ' ', $value;

    # only one global auth setting for now
    my $token = $self->{config}->{phabricator_auth_token};

    my $tempdir = File::Temp->newdir("phab-diff" . "XXXXX", TMPDIR => 1);

    system("arc --conduit-token=$token export --git --revision $diffId --conduit-uri=$phabUrl > $tempdir/$diffId.patch");

    my $storePath = trim(`nix-store --add "$tempdir/$diffId.patch"`
        or die "cannot copy path $tempdir to the Nix store.\n");
    chomp $storePath;
    my $timestamp = time;
    return { storePath => $storePath, revision => strftime "%Y%m%d%H%M%S", gmtime($timestamp) };
}

1;
