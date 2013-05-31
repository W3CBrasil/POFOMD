
package POFOMD::Schema::Result::Gasto;

use strict;
use warnings;
use base 'DBIx::Class::Core';
use POFOMD::Utils qw(formata_valor);

__PACKAGE__->table('gasto');
__PACKAGE__->add_columns(
    'dataset_id'      => { 'data_type' => 'integer' },
    'funcao_id'       => { 'data_type' => 'integer' },
    'subfuncao_id'    => { 'data_type' => 'integer' },
    'programa_id'     => { 'data_type' => 'integer' },
    'acao_id'         => { 'data_type' => 'integer' },
    'beneficiario_id' => { 'data_type' => 'integer' },
    'despesa_id'      => { 'data_type' => 'integer' },
    'pagamento_id'    => { 'data_type' => 'integer' },
    'gestora_id'      => { 'data_type' => 'integer' },
    'recurso_id'      => { 'data_type' => 'integer' },
    'valor'           => { 'data_type' => 'float' }
);

__PACKAGE__->set_primary_key(
    qw/dataset_id funcao_id subfuncao_id programa_id acao_id beneficiario_id despesa_id pagamento_id gestora_id recurso_id/
);

__PACKAGE__->belongs_to(
    dataset => 'POFOMD::Schema::Result::Dataset' =>
      { 'foreign.id' => 'self.dataset_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    funcao => 'POFOMD::Schema::Result::Funcao' =>
      { 'foreign.id' => 'self.funcao_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    subfuncao => 'POFOMD::Schema::Result::Subfuncao' =>
      { 'foreign.id' => 'self.subfuncao_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    programa => 'POFOMD::Schema::Result::Programa' =>
      { 'foreign.id' => 'self.programa_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    acao => 'POFOMD::Schema::Result::Acao' =>
      { 'foreign.id' => 'self.acao_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    beneficiario => 'POFOMD::Schema::Result::Beneficiario' =>
      { 'foreign.id' => 'self.beneficiario_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);
__PACKAGE__->belongs_to(
    despesa => 'POFOMD::Schema::Result::Despesa' =>
      { 'foreign.id' => 'self.despesa_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);

__PACKAGE__->belongs_to(
    pagamento => 'POFOMD::Schema::Result::Pagamento' =>
      { 'foreign.id' => 'self.pagamento_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);

__PACKAGE__->belongs_to(
    gestora => 'POFOMD::Schema::Result::Gestora' =>
      { 'foreign.id' => 'self.gestora_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);

__PACKAGE__->belongs_to(
    recurso => 'POFOMD::Schema::Result::Recurso' =>
      { 'foreign.id' => 'self.recurso_id' },
    {
        is_deferrable => 1,
        on_delete     => "CASCADE",
        on_update     => "CASCADE"
    },
);

sub total { formata_valor( shift->valor ) }

1;
