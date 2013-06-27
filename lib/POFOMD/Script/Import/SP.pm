package POFOMD::Script::Import::SP;
use Moose;
use namespace::autoclean;
use POFOMD ();
use Text::Unaccent::PurePerl ();
use Text::CSV_XS;
use Text2URI;
use DateTime;
use autodie;
use utf8;
use Data::Dumper;

with 'MooseX::Getopt::GLD';

my $CACHE_INSERTING = {};
my $UPDATE_FH;

has _csv_obj => (
    is      => 'ro',
    default => sub {
        Text::CSV_XS->new({
            allow_loose_quotes => 1,
            binary             => 1,
            verbatim           => 0,
            auto_diag          => 1,
            escape_char        => undef,
        });
    }
);

has _text2uri => (
    is      => 'ro',
    isa     => 'Text2URI',
    default => sub { Text2URI->new },
);

has _schema => (
    is      => 'ro',
    isa     => 'DBIx::Class::Schema',
    default => sub { POFOMD->model('DB')->schema },
);

has _resultsets => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return +{
            map { $_ => $self->_schema->resultset($_) }
              qw/Funcao Subfuncao Programa Acao Beneficiario Despesa Gestora Recurso/
        };
    },
);

has year => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {
        return DateTime->now->year;
    },
    documentation => "The year of the dataset csv to be inserted",
);

has dataset => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "The csv file downloaded from: "
    . "https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/DownloadReceitas.aspx?flag=2&ano=\$year \n"
    . "Replace \$year with the year you are interested in.",
);

has _dataset_name => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Estado de São Paulo',
);

has _dataset_id => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_dataset_id',
);

sub _build_dataset_id {
    my ($self) = @_;

    my $year       = $self->year;
    my $schema     = $self->_schema;
    my $t          = $self->_text2uri;
    my $dataset_rs = $schema->resultset('Dataset');
    my $periodo_rs = $schema->resultset('Periodo');

    return $dataset_rs->find_or_create(
        {
            nome    => $self->_dataset_name,
            periodo => $periodo_rs->find_or_create( { ano => $year } ),
            uri     => $t->translate( join( '-', 'estado-sao-paulo', $year ) ),
        }
    )->id;
}

sub run {
    my ($self) = @_;

    unless ($self->dataset) {
        print "Dataset file is mandatory.\n";
        print "See --usage for details.\n";
        exit(0);
    }

    my $start_time = DateTime->now;

    while (my ($k, $v) = each %{ $self->_resultsets }) {
        $self->_load_from_database($k, $v);
    }

    open $UPDATE_FH, '>>', 'update_sp.log';
    open my $fh, '<:encoding(iso-8859-1)', $self->dataset;

    $self->load_csv_into_db($fh);

    close $fh;
    close $UPDATE_FH;

    my $end_time = DateTime->now;

    my $elapse = $end_time - $start_time;

    printf(
        "Finished loading CSV (year %d) for %s in %d minutes.\n",
        $self->year, $self->_dataset_name, $elapse->in_units('minutes')
    )
}

sub load_csv_into_db {
    my ($self, $fh) = @_;

    my $pagamento_rs= $self->_schema->resultset('Pagamento');
    my $gasto_rs    = $self->_schema->resultset('Gasto');
    my $dataset_id  = $self->_dataset_id;

    my $csv = $self->_csv_obj;
    $csv->bind_columns(
        \my (
            $ANO_DE_REFERENCIA,         $CODIGO_ORGAO,
            $NOME_ORGAO,                $CODIGO_UNIDADE_ORCAMENTARIA,
            $NOME_UNIDADE_ORCAMENTARIA, $CODIGO_UNIDADE_GESTORA,
            $NOME_UNIDADE_GESTORA,      $CODIGO_CATEGORIA_DE_DESPESA,
            $NOME_CATEGORIA_DE_DESPESA, $CODIGO_GRUPO_DE_DESPESA,
            $NOME_GRUPO_DE_DESPESA,     $CODIGO_MODALIDADE,
            $NOME_MODALIDADE,           $CODIGO_ELEMENTO_DE_DESPESA,
            $NOME_ELEMENTO_DE_DESPESA,  $CODIGO_ITEM_DE_DESPESA,
            $NOME_ITEM_DE_DESPESA,      $CODIGO_FUNCAO,
            $NOME_FUNCAO,               $CODIGO_SUBFUNCAO,
            $NOME_SUBFUNCAO,            $CODIGO_PROGRAMA,
            $NOME_PROGRAMA,             $CODIGO_PROGRAMA_DE_TRABALHO,
            $NOME_PROGRAMA_DE_TRABALHO, $CODIGO_FONTE_DE_RECURSOS,
            $NOME_FONTE_DE_RECURSOS,    $NUMERO_PROCESSO,
            $NUMERO_NOTA_DE_EMPENHO,    $CODIGO_CREDOR,
            $NOME_CREDOR,               $CODIGO_ACAO,
            $NOME_ACAO,                 $TIPO_LICITACAO,
            $VALOR_EMPENHADO,           $VALOR_LIQUIDADO,
            $VALOR_PAGO,                $VALOR_PAGO_DE_ANOS_ANTERIORES
        )
    );

    my $t    = $self->_text2uri;
    my $line = 0;
    # $gasto_rs->search({ dataset_id => $dataset_id })->delete;

    while ( my $row = $csv->getline($fh) ) {
        $line++;

        next
          if $CODIGO_FUNCAO eq 'CODIGO FUNCAO' or !$VALOR_LIQUIDADO;

        $VALOR_PAGO_DE_ANOS_ANTERIORES ||= 0;
        $TIPO_LICITACAO                ||= 'nao-informado';

        $VALOR_EMPENHADO =~ s/\,/\./g;
        $VALOR_LIQUIDADO =~ s/\,/\./g;
        $VALOR_LIQUIDADO =~ s/\,/\./g;
        $VALOR_PAGO_DE_ANOS_ANTERIORES =~ s/\,/\./g;

        my $pagamento ||= $pagamento_rs->create({
            numero_processo            => $NUMERO_PROCESSO,
            numero_nota_empenho        => $NUMERO_NOTA_DE_EMPENHO,
            tipo_licitacao             => $TIPO_LICITACAO,
            valor_empenhado            => $VALOR_EMPENHADO,
            valor_liquidado            => $VALOR_LIQUIDADO,
            valor_pago_anos_anteriores => $VALOR_PAGO_DE_ANOS_ANTERIORES,
        });

        my $obj = $gasto_rs->create({
            dataset_id => $dataset_id,

            $self->_cache_or_create(
                funcao => 'Funcao',
                {
                    codigo => $CODIGO_FUNCAO,
                    nome   => $NOME_FUNCAO,
                }
            ),

            $self->_cache_or_create(
                subfuncao => 'Subfuncao',
                {
                    codigo => $CODIGO_SUBFUNCAO,
                    nome => $NOME_SUBFUNCAO,
                }
            ),

            $self->_cache_or_create(
                programa => 'Programa',
                {
                    codigo => $CODIGO_PROGRAMA,
                    nome   => $NOME_PROGRAMA,
                }
            ),

            $self->_cache_or_create(
                acao => 'Acao',
                {
                    codigo => $CODIGO_ACAO,
                    nome   => $NOME_ACAO,
                }
            ),

            $self->_cache_or_create_beneficiario(
                {
                    codigo    => $CODIGO_CREDOR,
                    nome      => $NOME_CREDOR,
                    documento => '0',
                    uri       => $t->translate( _unaccent($NOME_CREDOR) ),
                }
            ),

            $self->_cache_or_create(
                despesa => 'Despesa',
                {
                    codigo => $CODIGO_GRUPO_DE_DESPESA,
                    nome   => $NOME_GRUPO_DE_DESPESA,
                }
            ),

            $self->_cache_or_create(
                gestora => 'Gestora',
                {
                    codigo => $CODIGO_UNIDADE_GESTORA,
                    nome   => $NOME_UNIDADE_GESTORA,
                }
            ),

            pagamento => $pagamento,

            $self->_cache_or_create(
                recurso => 'Recurso',
                {
                    codigo => $CODIGO_FONTE_DE_RECURSOS,
                    nome   => $NOME_FONTE_DE_RECURSOS,
                }
            ),

            valor => $VALOR_LIQUIDADO
        });

        debug("$line - %s");
        debug();
    }
}

sub _load_from_database {
    my ($self, $campo) = @_;

    my $campo_lc = lc $campo;
    my @rows = $self->_schema->resultset($campo)->search({}, {
        columns => [ 'codigo', 'id' ]
    })->all;

    for my $r (@rows) {
        $CACHE_INSERTING->{$campo_lc}{$r->codigo} = $r->id;
    }

    @rows = (); # force Perl to release memory
}

sub _cache_or_create {
    my ($self, $campo, $set, $info) = @_;

    my $codigo = $info->{codigo};
    my $id;

    if (exists $CACHE_INSERTING->{$campo}{$codigo}){
        $id = $CACHE_INSERTING->{$campo}{$codigo};
        # debug("\tloading from cache: $campo");
    }
    else {
        my $obj = $self->_resultsets->{$set}->create($info);

        $CACHE_INSERTING->{$campo}{$codigo} = $id = $obj->id;
    }

    return ($campo . '_id' => $id);
}

sub _cache_or_create_beneficiario {
    my ($self, $info) = @_;

    my $campo = 'beneficiario';
    my $set   = 'Beneficiario';

    my $created = 0;
    my $rs      = $self->_resultsets->{$set};
    my $codigo  = $info->{codigo};
    my $id;

    if (exists $CACHE_INSERTING->{$campo}{$codigo}){
        $id = $CACHE_INSERTING->{$campo}{$codigo};
        debug("\tloading from cache: $campo");
    }
    else {
        my $obj = $rs->find( { codigo => $codigo } )
          || $rs->find( { uri => $info->{uri} } );

        if (!$obj) {
            $obj = $rs->create( $info );
            $created = 1;
        }

        $CACHE_INSERTING->{$campo}{$codigo} = $id = $obj->id;
    }

    if (!$created) {
        my $value = Dumper($info);
        print $UPDATE_FH "$id => $value";
        #$rs->find($id)->update($info);
    }

    return ($campo . '_id' => $id);
}

sub _unaccent {
    return Text::Unaccent::PurePerl::unac_string('UTF-8', $_[0]);
}

sub debug {
    my ($string, $obj) = @_;

    $string ||= '';
    my $what_happened = "";

    if ($obj) {
        $what_happened = "found in db";

        if (!$obj->in_storage) {
            $what_happened = "inserted into db";
            $obj->insert;
        }
    }

    printf("$string\n", $what_happened);
}

__PACKAGE__->meta->make_immutable;

1;
