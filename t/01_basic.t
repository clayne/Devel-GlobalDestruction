use strict;
use warnings;

BEGIN {
    if ($ENV{DEVEL_GLOBALDESTRUCTION_PP_TEST}) {
        require DynaLoader;
        no warnings 'redefine';
        my $orig = \&DynaLoader::bootstrap;
        *DynaLoader::bootstrap = sub {
            die 'no XS' if $_[0] eq 'Devel::GlobalDestruction';
            goto $orig;
        };
    }
}

BEGIN {
    package Test::Scope::Guard;
    sub new { my ($class, $code) = @_; bless [$code], $class; }
    sub DESTROY { my $self = shift; $self->[0]->() }
}

print "1..4\n";

sub ok ($$) {
    print "not " if !$_[0];
    print "ok";
    print " - $_[1]" if defined $_[1];
    print "\n";
}

ok( eval "use Devel::GlobalDestruction; 1", "use Devel::GlobalDestruction" );

ok( defined &in_global_destruction, "exported" );

ok( !in_global_destruction(), "not in GD" );

our $sg = Test::Scope::Guard->new(sub { ok( in_global_destruction(), "in GD" ) });
