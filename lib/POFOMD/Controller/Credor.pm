package POFOMD::Controller::Credor;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use POFOMD::Utils qw(formata_real formata_valor formata_float bgcolor);

sub base : Chained('/base') : PathPart('') : CaptureArgs(0) {
}

sub credor : Chained('base') : PathPart('credor') : CaptureArgs(1) {
    my ( $self, $c, $uri ) = @_;
    my $ds = $c->model('DB::Beneficiario');
    my $ds_obj = $ds->find( { uri => $uri } );
    $c->detach if !$ds_obj;
    $c->stash->{credor} = $ds_obj;
}

sub root : Chained('credor') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $page = $c->req->param('page') || 1;
    $c->stash->{gastos} =
      $c->model('DB::Gasto')
      ->search( { beneficiario_id => $c->stash->{credor}->id },
        { rows => 50, page => $page } );

    $c->stash->{page} = $page;
}

sub credores : Chained('base') PathParth('credores') : CaptureArgs(0) {
}

sub busca : Chained('credores') : Args(0) {
    my ( $self, $c ) = @_;

    my $query = uc($c->req->param('q'));
    my $page  = $c->req->param('page') || 1;
    my $rs    = $c->model('DB::Beneficiario');

    my $credores = $rs->search( { nome => { like => "\%$query\%" } },
        { page => $page, rows => 50 } );

    if ( $credores == 1 ) {
        $c->res->redirect( join( '/', '', 'credor', $credores->first->uri ) );
    }

    $c->stash->{credores} = $credores;
}

sub sugestao : Chained('credores') Args(0) {
    my ( $self, $c ) = @_;
    my $query = uc($c->req->param('q'));
    my $rs    = $c->model('DB::Beneficiario');
    my $objs  = $rs->search(
        { nome => { like => "$query\%" } },
        {
            select => 'nome',
            as     => 'nome',
            rows   => 10,
            page   => 1
        }
    );
    my @nomes;
    for my $item ( $objs->all ) {
        push( @nomes, $item->nome );
    }
    $c->stash->{nomes} = \@nomes;
    $c->forward('View::JSON');
}

__PACKAGE__->meta->make_immutable;

1;
