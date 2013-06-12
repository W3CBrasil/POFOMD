package POFOMD::Schema::Result::Pagamento;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table('pagamento');
__PACKAGE__->add_columns(
    'id' => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => 'pagamento_id_seq',
    },
    'numero_processo'     => { data_type => 'varchar' },
    'numero_nota_empenho' => { data_type => 'varchar' },
    'tipo_licitacao'      => { data_type => 'varchar' },
    'valor_empenhado'     => { data_type => 'float', default_value => 0 },
    'valor_liquidado'     => { data_type => 'float' },
    'valor_pago_anos_anteriores' => { data_type => 'float', default_value => 0 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraints(
    [ qw/numero_processo/     ],
    [ qw/numero_nota_empenho/ ],
);

__PACKAGE__->has_many(
    'gastos',
    'POFOMD::Schema::Result::Gasto',
    { "foreign.pagamento_id" => "self.id" },
    { cascade_copy           => 0, cascade_delete => 0 },
);

1;
