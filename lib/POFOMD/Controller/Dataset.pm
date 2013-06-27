package POFOMD::Controller::Dataset;
use utf8;
use Moose;
use CHI;
use namespace::autoclean;

BEGIN { extends 'POFOMD::HandleTree' }

use POFOMD::Utils qw(formata_real formata_valor formata_float bgcolor);

sub list : Chained('/base') : PathPart('datasets') : Args(0) {
    my ( $self, $c ) = @_;

    # TODO: integrate better with Catalyst
    my $cache = CHI->new(
        driver => 'FastMmap',
        root_dir => $c->path_to('/tmp/fastmmap-cache/')->stringify,
        cache_size => '100m',
    );

    my ($dts, $total_all) = $cache->compute('dataset_overview_list', '24 hours', sub {
        _get_list($c)
    });

    $c->stash(
        dataset_text => 'Visão Geral',
        data         => $dts,
        total_all    => $total_all,
    );
    $c->forward('View::JSON');
}

sub base : Chained('/base') : PathPart('dataset') : CaptureArgs(1) {
    my ( $self, $c, $uri ) = @_;
    my $ds = $c->model('DB::Dataset');
    my $ds_obj = $ds->find( { uri => $uri } );
    $c->detach if !$ds_obj;
    $c->stash->{dataset} = $ds_obj;
    $c->stash->{rs} =
      $c->model('DB::Gasto');    #->search_rs({ dataset_id => $dataset });
}

sub year : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c, $year ) = @_;
    $c->stash->{template} = 'node.tt';
    $c->stash->{node} =
      join( '/', '', 'dataset', $c->stash->{dataset}->uri, 'data' );
    $c->stash->{dataset_text} = join(' - ', $c->stash->{dataset}->nome, $c->stash->{dataset}->periodo->ano);

}

sub root : Chained('year') PathPart('') Args(0) {}

sub root_list : Chained('/base') PathPart('datasets/overview') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'datasets.tt';
}

sub root_funcoes : Chained('year') PathPart('') Args(1) {
    my ( $self, $c, $funcao_id ) = @_;
    $c->stash->{node} = join( '/', $c->stash->{node}, $funcao_id );
    $c->stash->{nodetype} = 'funcao';
}

sub root_subfuncoes : Chained('year') PathPart('') Args(2) {
    my ( $self, $c, $funcao_id, $subfuncao_id ) = @_;
    $c->stash->{node} =
      join( '/', $c->stash->{node}, $funcao_id, $subfuncao_id );
    $c->stash->{nodetype} = 'subfuncao';
}

sub root_programas : Chained('year') PathPart('') Args(3) {
    my ( $self, $c, $funcao_id, $subfuncao_id, $programa_id ) = @_;
    $c->stash->{node} =
      join( '/', $c->stash->{node}, $funcao_id, $subfuncao_id, $programa_id );
    $c->stash->{nodetype} = 'programa';
}

sub root_acoes : Chained('year') PathPart('') Args(4) {
    my ( $self, $c, $funcao_id, $subfuncao_id, $programa_id, $acao_id ) = @_;
    $c->stash->{node} = join( '/',
        $c->stash->{node}, $funcao_id, $subfuncao_id, $programa_id, $acao_id );
    $c->stash->{nodetype} = 'acao';
}

sub data : Chained('year') CaptureArgs(0) {
    my ( $self, $c );
}

sub data_root : Chained('data') : PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    # TODO: integrate better with Catalyst
    my $cache = CHI->new(
        driver => 'FastMmap',
        root_dir => $c->path_to('/tmp/fastmmap-cache/')->stringify,
        cache_size => '100m',
    );

    my $data = $cache->compute('dataset_funcoes_' . $c->stash->{dataset_text}, '24 hours', sub {
        _get_data_root($c)
    });

    $c->stash->{data} = $data;
    $c->forward('handle_TREE');
}

sub data_funcao : PathPart('data') : Chained('year') : Args(1) {
    my ( $self, $c, $funcao_id ) = @_;
    $c->stash->{funcao_id}   = $funcao_id;
    $c->stash->{target_type} = 1;
    $c->stash->{target_name} = 'SUBFUNCAO';
    $c->forward('handle_DATA');
}

sub data_subfuncao : PathPart('data') : Chained('year') : Args(2) {
    my ( $self, $c, $funcao_id, $subfuncao_id ) = @_;
    $c->stash->{funcao_id}    = $funcao_id;
    $c->stash->{subfuncao_id} = $subfuncao_id;
    $c->stash->{target_type}  = 2;
    $c->stash->{target_name}  = 'PROGRAMA';
    $c->forward('handle_DATA');
}

sub data_programas : PathPart('data') : Chained('year') : Args(3) {
    my ( $self, $c, $funcao_id, $subfuncao_id, $programa_id ) = @_;
    $c->stash->{funcao_id}    = $funcao_id;
    $c->stash->{subfuncao_id} = $subfuncao_id;
    $c->stash->{programa_id}  = $programa_id;
    $c->stash->{target_type}  = 3;
    $c->stash->{target_name}  = 'ACAO';
    $c->forward('handle_DATA');
}

sub data_acoes : PathPart('data') : Chained('year') : Args(4) {
    my ( $self, $c, $funcao_id, $subfuncao_id, $programa_id, $acao_id ) = @_;
    $c->stash->{funcao_id}    = $funcao_id;
    $c->stash->{subfuncao_id} = $subfuncao_id;
    $c->stash->{programa_id}  = $programa_id;
    $c->stash->{acao_id}      = $acao_id;
    $c->stash->{target_type}  = 4;
    $c->stash->{target_name}  = 'CREDOR';
    $c->forward('handle_DATA');
}

sub handle_DATA : Private {
    my ( $self, $c ) = @_;

    my $target_type = $c->stash->{target_type};
    my $rs          = $c->stash->{rs};
    my @data;
    my $total_all = 0;

    my $args;
    $args->{dataset_id}   = $c->stash->{dataset}->id;
    $args->{funcao_id}    = $c->stash->{funcao_id};
    $args->{subfuncao_id} = $c->stash->{subfuncao_id}
      if $c->stash->{subfuncao_id};
    $args->{programa_id} = $c->stash->{programa_id} if $c->stash->{programa_id};
    $args->{acao_id}     = $c->stash->{acao_id}     if $c->stash->{acao_id};

    if ( $target_type == 1 ) {
        my $search = $rs->search(
            $args,
            {
                select => [
                    'dataset_id', 'funcao_id',
                    'subfuncao_id', { sum => 'valor' }
                ],
                as       => [qw/dataset_id funcao_id subfuncao_id valor/],
                group_by => [qw/dataset_id funcao_id subfuncao_id/]
            }
        );

        foreach my $item ( $search->all ) {

            push(
                @data,
                {
                    id => join( '.',
                        $item->dataset_id, $item->funcao_id,
                        $item->subfuncao_id ),
                    display => $item->subfuncao->nome,
                    link    => $item->subfuncao_id,
                    total   => $item->valor
                }
            );

            # Soma total para utilizar na porcentagem dos credores
            $total_all += $item->valor;
        }
    }

    if ( $target_type == 2 ) {
        my $search = $rs->search(
            $args,
            {
                select => [
                    'dataset_id',   'funcao_id',
                    'subfuncao_id', 'programa_id',
                    { sum => 'valor' }
                ],
                as => [qw/dataset_id funcao_id subfuncao_id programa_id valor/],
                group_by => [qw/dataset_id funcao_id subfuncao_id programa_id/]
            }
        );

        foreach my $item ( $search->all ) {

            push(
                @data,
                {
                    id => join( '.',
                        $item->dataset_id,   $item->funcao_id,
                        $item->subfuncao_id, $item->programa_id ),
                    display => $item->programa->nome,
                    link    => $item->programa_id,
                    total   => $item->valor
                }
            );

            # Soma total para utilizar na porcentagem dos credores
            $total_all += $item->valor;
        }
    }

    if ( $target_type == 3 ) {
        my $search = $rs->search(
            $args,
            {
                select => [
                    'dataset_id',   'funcao_id',
                    'subfuncao_id', 'programa_id',
                    'acao_id', { sum => 'valor' }
                ],
                as => [
                    qw/dataset_id funcao_id subfuncao_id programa_id acao_id valor/
                ],
                group_by =>
                  [qw/dataset_id funcao_id subfuncao_id programa_id acao_id/]
            }
        );

        foreach my $item ( $search->all ) {

            push(
                @data,
                {
                    id => join( '.',
                        $item->dataset_id,   $item->funcao_id,
                        $item->subfuncao_id, $item->programa_id,
                        $item->acao_id ),
                    display => $item->acao->nome,
                    link    => $item->acao_id,
                    total   => $item->valor
                }
            );

            # Soma total para utilizar na porcentagem dos credores
            $total_all += $item->valor;
        }
    }

    if ( $target_type == 4 ) {
        my $search = $rs->search(
            $args,
            {
                select => [
                    'dataset_id',   'funcao_id',
                    'subfuncao_id', 'programa_id',
                    'acao_id',      'beneficiario_id',
                    { sum => 'valor' }
                ],
                as => [
                    qw/dataset_id funcao_id subfuncao_id programa_id acao_id beneficiario_id valor/
                ],
                group_by => [
                    qw/dataset_id funcao_id subfuncao_id programa_id acao_id beneficiario_id/
                ]
            }
        );

        foreach my $item ( $search->all ) {

            push(
                @data,
                {
                    id => join( '.',
                        $item->dataset_id,   $item->funcao_id,
                        $item->subfuncao_id, $item->programa_id,
                        $item->acao_id,      $item->beneficiario_id ),
                    display => $item->beneficiario->nome,
                    fplink  => '/credor/' . $item->beneficiario->uri,
                    total   => $item->valor
                }
            );

            # Soma total para utilizar na porcentagem dos credores
            $total_all += $item->valor;
        }
    }

    $c->stash->{data} = \@data;
    $c->forward('handle_TREE');
}

sub _get_list {
    my ($c) = @_;
    my $gasto = $c->model('DB::Gasto');
    my $rs    = $c->model('DB::Dataset')->search({}, {
        columns    => [ 'id', 'nome', 'uri' ],
        '+columns' => [ 'periodo.ano' ],
        join       => 'periodo',
    });
    my @dts;

    my $total_all = 0;
    foreach my $item ( $rs->all ) {
        my $search = $gasto->search(
            { dataset_id => $item->id },
            {
                select   => [ 'dataset_id', { sum => 'valor' } ],
                as       => [qw/dataset_id valor/],
                group_by => 'dataset_id'
            }
        );

        my $obj = $search->first or next;

        # TODO : Adicionar tipo de base no dataset.
        my $type = $item->uri;
        $type =~ s/\-.*//g;
        $type = 'estado2' if $item->uri =~ 'rio';

        my $count = $gasto->search( { dataset_id => $item->id } )->count;

        push(
            @dts,
            {
                dataset_id => $item->id,
                periodo    => $item->periodo->ano,
                valor      => $obj->valor,
                total      => formata_real( $obj->valor ),
                items      => $count / 100,
                items_real => $count,
                type       => $type,
                titulo     => $item->nome,
                uri        => $item->uri
            }
        );
        $total_all += $obj->valor;
    }

    return (\@dts, $total_all);
}

sub _get_data_root {
    my $c = shift;

    my @data;
    my $rs     = $c->stash->{rs};
    my $search = $rs->search(
        { dataset_id => $c->stash->{dataset}->id },
        {
            select => [ 'dataset_id', 'funcao_id', { sum => 'valor' } ],
            as       => [qw/dataset_id funcao_id valor/],
            group_by => [qw/dataset_id funcao_id/]
        }
    );

    foreach my $item ( $search->all ) {

        # Preparando dados para handle_TREE
        push(
            @data,
            {
                id      => join( '.', $item->dataset_id, $item->funcao_id ),
                display => $item->funcao->nome,
                link    => $item->funcao_id,
                total   => $item->valor
            }
        );
    }

    return \@data;
}

__PACKAGE__->meta->make_immutable;

1;
