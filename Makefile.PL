#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'POFOMD';
all_from 'lib/POFOMD.pm';

requires 'Catalyst::Runtime' => '5.90010';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General';
requires 'autodie';
requires 'DateTime';

requires 'Catalyst::View::TT';
requires 'Catalyst::View::JSON';
requires 'FCGI';
requires 'FCGI::ProcManager';
requires 'XML::Simple';
requires 'MooseX::Types::JSON';

requires 'Text::Unaccent';
requires 'Text::Unidecode';
requires 'Text::CSV';
requires 'Text::CSV_XS';
requires 'Text2URI';

requires 'SQL::Translator';
requires 'DBIx::Class';
requires 'Catalyst::Model::DBIC::Schema';
requires 'DBIx::Class::ResultClass::HashRefInflator';
requires 'DBD::Pg';
requires 'Redis';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
