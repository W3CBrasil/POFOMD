package POFOMD::HandleTree;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use POFOMD::Utils qw(formata_real formata_valor formata_float bgcolor);

sub handle_TREE : Private {
    my ( $self, $c ) = @_;

    my $total = 0;
    map { $total += $_->{total} } @{ $c->stash->{data} };
    $c->stash->{total_tree} = formata_real( $total, 2 );

    my @children;
    my @bgcolor         = bgcolor;
    my $bgcolor_default = '#c51d18';    # in config file ?

    foreach my $item ( @{ $c->stash->{data} } ) {
        next unless $item->{total};

        my $uri = $c->req->uri->path;
        $uri =~ s/^(\/.*)(\/.*)\/data/$1$2/;

        my $valor_porcentagem = $item->{total} * 100 / $total;
        my $color             = shift(@bgcolor) || $bgcolor_default;
        my $valor_print       = formata_valor( $item->{total} );
        my $porcentagem       = formata_float( $valor_porcentagem, 3 );
        my $zone              = '/';
        my $link              = $item->{fplink} ? $item->{fplink} : join('/', $uri, $item->{link});
        my $title = $item->{display};

        push(
            @children,
            {   data => {
                    title           => $title,
                    '$area'         => $porcentagem,
                    '$color'        => $color,
                    value           => $porcentagem,
                    printable_value => $valor_print,
                    porcentagem     => $porcentagem,
                    valor_tabela    => formata_real( $item->{total} ),
                    link            => $link,

                    ( $valor_porcentagem > 3 )
                    ? ( show_title => 'true' )
                    : (),

                },
                children => [],
                name     => $title,
                id       => $item->{id}
            }
        );
    }
    $c->stash->{children} = [@children];

    my @zones;
    my @zones_a;
    my $uri = $c->stash->{dataset} ? $c->stash->{dataset}->uri || '#' : '#';
    my $uri_name = $c->stash->{dataset} ? join(', ',$c->stash->{dataset}->nome, $c->stash->{dataset}->periodo->ano) || '' : '';

    @zones_a = ( { content => $uri_name, id => "/dataset/$uri" } );

    my $base_url = $c->stash->{dataset} ? join('/', '', 'dataset', $c->stash->{dataset}->uri) : '/';

    if ($c->stash->{funcao_id}) {
        $base_url = join('/', $base_url, $c->stash->{funcao_id});
        my $obj = $c->model('DB::Funcao')->find($c->stash->{funcao_id});
        push(@zones_a, ( { content => $obj->nome, id => $base_url } ) ) if $obj;
    }

    if ($c->stash->{subfuncao_id}) {
        $base_url = join('/', $base_url, $c->stash->{subfuncao_id});
        my $obj = $c->model('DB::Subfuncao')->find($c->stash->{subfuncao_id});
        push(@zones_a, ( { content => $obj->nome, id => $base_url } ) ) if $obj;
    }

    if ($c->stash->{programa_id}) {
        $base_url = join('/', $base_url, $c->stash->{programa_id});
        my $obj = $c->model('DB::Programa')->find($c->stash->{programa_id});
        push(@zones_a, ( { content => $obj->nome, id => $base_url } ) ) if $obj;
    }

    if ($c->stash->{acao_id}) {
        $base_url = join('/', $base_url, $c->stash->{acao_id});
        my $obj = $c->model('DB::Acao')->find($c->stash->{acao_id});
        push(@zones_a, ( { content => $obj->nome, id => $base_url } ) ) if $obj;
    }



    $c->stash->{zones} = join( ', ', @zones ) if @zones;
    $c->stash->{zones_a} = [ @zones_a ];

    delete $c->stash->{target_keys};
    delete $c->stash->{target_type};
    delete $c->stash->{target_name};
    delete $c->stash->{data};
    delete $c->stash->{redis};
    delete $c->stash->{rs};
    delete $c->stash->{dataset};

    $c->forward('View::JSON');
}

1;
