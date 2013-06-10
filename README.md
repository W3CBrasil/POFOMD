Para onde foi o meu dinheiro?
=============================

[http://www.paraondefoiomeudinheiro.com.br](http://www.paraondefoiomeudinheiro.com.br)

Sistema elaborado para demonstrar os gastos públicos, classificados por FUNÇÃO de Governo e seus detalhamentos. Esta ferramenta permite ao usuário conhecer toda a tramitação orçamentária, indicando inclusive quem recebeu o recurso empenhado. A proposta é fornecer condições de maior clareza do destino dos tributos, bem como maior “mobilidade” no manuseio das informações obtidas.

Rodando o projeto localmente para testes
----------------------------------------

* Para essa simulação foi utilizado o Ubuntu 12.10 (Versão Desktop) 32 bits

1. Instalando os pacotes do sistema que serão necessários:

        $ sudo apt-get install git postgresql postgresql-server-dev-all cpanminus libxml-sax-expat-perl libdbix-class-perl

2. Ajustando as configurações do PostgreSQL:

        $ sudo su - postgres
        $ createuser -E -P seu_user
        $ createdb -O seu_user seu_db
        $ exit

3. Clonando o projeto:

        $ git clone http://github.com/W3CBrasil/POFOMD.git

4. Instalando as dependencias do perl:

        $ cd POFOMD
        $ sudo cpanm inc::Module::Install
        $ sudo cpanm Module::Install::Catalyst
        $ sudo cpanm --installdeps .

5. Instalar as tabelas do banco de dados:

        $ dbicadmin -Ilib --schema=POFOMD::Schema --connect='["dbi:Pg:host=localhost;dbname=seu_db", "seu_user", "seu_pass"]' --deploy

6. Edite o arquivo pofomd.conf, na raiz do projeto, e coloque as suas configurações corretas de conexão com o banco.

7. Preparando a base de testes:
  * Faça o download do arquivo de exemplo no link https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/DownloadReceitas.aspx?flag=2&ano=2012
  * Descompacte o arquivo;
  * Edite o arquivo de importação script/import/sp_to_pg.pl e configure corretamente suas credenciais de banco;
  * Execute o arquivo de migração:

            $ perl -Ilib script/import/sp_to_pg.pl 2012 path/para/o/seu/arquivo.csv

8. Rodando o servidor de teste:

        $ ./script/pofomd_server.pl -r
