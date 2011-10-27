package Test::MySQL::Schema;
use strict;
use warnings;

our $VERSION = '0.01';

use Test::mysqld;
use DBI;
use Path::Class;
use Text::Diff ();

# $config = +{
#     database     => 'test',
#     schema_file  => '/path/to/file.sql',
#     connect_info => $connect_info,
# };

sub test_schema {
    my $config = shift;

    my ($base_tables, $base_tables_schema);
    do {
        my $mysqld = Test::mysqld->new(
            my_cnf => {
                'skip-networking' => '',
            }
        ) or die $Test::mysqld::errstr;

        my $dsn = $mysqld->dsn() . ';mysql_multi_statements=1';
        my $dbh = DBI->connect($dsn, '','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
        my $database = $config->{database};
        $dbh->do("create database $database");

        my $sql = "use $database;\n";
        $sql   .= "set names utf8;\n";
        $sql   .= file($config->{schema_file})->slurp;
        $dbh->do($sql);

        $base_tables = $dbh->selectcol_arrayref('SHOW TABLES');

        for my $table (@$base_tables) {
            my @info = $dbh->selectrow_array(sprintf('SHOW CREATE TABLE %s', $table));
            $base_tables_schema->{$table} = $info[1];
        }
    };

    do {
        my $dbh = DBI->connect(@{$config->{connect_info}},{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
        my $tables = $dbh->selectcol_arrayref('SHOW TABLES');
        my $diff = Text::Diff::diff($base_tables, $tables, { STYLE => "Table" });
        if ($diff) {
            print "$diff\n";
        }

        for my $table (@$tables) {
            my @info = $dbh->selectrow_array(sprintf('SHOW CREATE TABLE %s', $table));
            my $diff = Text::Diff::diff(\$base_tables_schema->{$table}, \$info[1], { STYLE => "Table" });
            if ($diff) {
                print "$diff\n";
            }
        }
    };
}

1;
__END__

=head1 NAME

Test::MySQL::Schema -

=head1 SYNOPSIS

  use Test::MySQL::Schema;

=head1 DESCRIPTION

Test::MySQL::Schema is

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
