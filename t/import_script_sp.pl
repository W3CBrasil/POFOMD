use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/../lib";
use POFOMD::Script::Import::SP;
use DateTime;

diag(q{DON'T RUN THIS ON THE LIVE SERVER!});

{
    my $script = POFOMD::Script::Import::SP->new(
        application_name => 'POFOMD',
        dataset          => "/non/existing/path/to/csv",
    );
    isa_ok($script, 'POFOMD::Script::Import::SP');
    is($script->year, DateTime->now->year, 'Year is correctly set to the default');
}

{
    my $script = POFOMD::Script::Import::SP->new(
        application_name => 'POFOMD',
        year             => 1500,
        dataset          => "$Bin/data/sp.sample.csv",
    );

    isa_ok($script->_csv_obj, 'Text::CSV_XS', 'the csv object');
    isa_ok($script->_text2uri, 'Text2URI', 'the Text2URI object');
    is($script->dataset, "$Bin/data/sp.sample.csv", "Dataset file is correctly set");
    is($script->year, 1500, "Year is correctly set");

    my $periodo_rs = $script->_schema->resultset('Periodo');
    my $gasto_rs = $script->_schema->resultset('Gasto');

    is($periodo_rs->count({ ano => 1500 }), 0, 'no year 1500 in the DB');
    ok(my $dataset_id = $script->_dataset_id, 'got dataset id');
    is($periodo_rs->count({ ano => 1500 }), 1, 'year 1500 inserted into the DB');

    is($gasto_rs->count({ dataset_id => $dataset_id }), 0, 'no expenses (gasto) with this dataset in the DB');
    ok((sub {
        open(my $fh, '>', \my $str);
        local *STDOUT = $fh;
        local *STDERR = $fh;
        $script->run;
        close($fh);
    })->(), 'script ran fine');
    is($gasto_rs->count({ dataset_id => $dataset_id }), 3, '3 expenses in this dataset in the DB');
    ok($periodo_rs->search({ ano => 1500 })->delete, 'delete year 1500');
    is($gasto_rs->count({ dataset_id => $dataset_id }), 0, 'expenses deleted');
}

done_testing;
