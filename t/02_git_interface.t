use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;
use File::Temp;
use File::Which qw/which/;
use HTTP::Request::Common;
use Test::Output;

use OrePAN2::Server::CLI;

my $git = which('git');
my $tar = which('tar');
unless ($git and $tar) {
    plan skip_all => "This test depends on git and tar commands";
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $app = OrePAN2::Server::CLI->new("--delivery-dir=$dir", '--delivery-path=/orepan', '--no-compress-index')->app;

test_psgi
    app    => $app,
    client => sub {
        my $cb = shift;
        subtest 'git interface' => sub {
            my $res = $cb->(POST "http://localhost/authenquery",
                Content      => +[
                    module => 'git@github.com:Songmu/p5-App-RunCron.git@0.03',
                ],
            );

            is $res->code, 200, 'success request ?';
            ok -f File::Spec->catfile($dir, qw/modules 02packages.details.txt/), 'is there 02packages.details.txt ?';
            ok -f File::Spec->catfile($dir, qw/authors id D DU DUMMY/, 'App-RunCron-0.03.tar.gz'), 'tarball exixts';
        };
    };

done_testing;

