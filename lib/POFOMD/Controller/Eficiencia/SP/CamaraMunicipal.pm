package POFOMD::Controller::Eficiencia::SP::CamaraMunicipal;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'POFOMD::HandleTree' }

use POFOMD::Utils qw(formata_real formata_valor formata_float bgcolor sum_redis_keys);
use Redis;

sub base : Chained('/base') : PathPart('eficiencia/sp/camaramunicipal') : CaptureArgs(1) {
    my ( $self, $c, $year ) = @_;
    $c->stash->{year}       = $year;
    $c->stash->{eficiencia} = 1;
    $c->stash->{redis}      = Redis->new;
}

sub data : Chained('base') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    delete $c->stash->{eficiencia};
}

sub modalidades : Chained('data') Args(0) {
    my ( $self, $c ) = @_;
    my $redis            = $c->stash->{redis};
    my $year             = $c->stash->{year};
    my @chaves_executado = $redis->keys("CMSP-MODALIDADE-PLANEJADO-$year-*");

    my @orcamento;

    map {
        my $categoria = $_;
        $categoria =~ s/CMSP-MODALIDADE-PLANEJADO-$year-//;
        my $executado = $redis->get("CMSP-MODALIDADE-EXECUTADO-$year-$categoria") || 0;
        my $planejado = $redis->get($_) || 0;
        my $key_name = "NAME-CMSP-MODALIDADE-PLANEJADO-$year-$categoria";
        my $name = $redis->get($key_name) || 'indefinido';

        push (@orcamento, {
            bacteria => $name,
            planejado => $planejado / 10000000,
            executado => $executado / 10000000,
            gram => $planejado && !$executado ? 'negative' : 'positive',
        });

    } @chaves_executado;

    $c->stash->{orcamento} = \@orcamento;

    $c->forward('handle_DATA');
}

sub root : Chained('base') PathPart('') : Args(0) {
}

sub credores : Chained('base') : Args(0) {
}

sub credor : Chained('base') : Args(1) {
    my ( $self, $c, $credor_id ) = @_;
}

sub handle_DATA : Private {
    my ( $self, $c ) = @_;
    delete $c->stash->{redis};
    $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
