requires "Modern::Perl";
requires "Getopt::Long";
requires "List::Util";
requires "LWP::UserAgent";
requires "LWP::Protocol::https";
requires "JSON";

on 'test' => sub {
    requires 'Test::More';
};

on 'develop' => sub {
    requires 'Devel::REPL';
    requires 'Lexical::Persistence';
    requires 'Data::Dump::Streamer';
    requires 'PPI';
};

