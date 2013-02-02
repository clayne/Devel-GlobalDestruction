package Devel::GlobalDestruction;

use strict;
use warnings;

our $VERSION = '0.09';

use Sub::Exporter::Progressive -setup => {
  exports => [ qw(in_global_destruction) ],
  groups  => { default => [ -all ] },
};

# we run 5.14+ - everything is in core
#
if (defined ${^GLOBAL_PHASE}) {
  eval 'sub in_global_destruction () { ${^GLOBAL_PHASE} eq q[DESTRUCT] }; 1'
    or die $@;
}
# try to load the xs version if it was compiled
#
elsif (eval {
  require XSLoader;
  XSLoader::load(__PACKAGE__, $VERSION);
  1;
}) {
  # the eval already installed everything, nothing to do
}
else {
  # internally, PL_main_start is nulled immediately before entering global destruction
  # and we can use B to detect that.  It will also be null before the main runloop starts,
  # so we check install a CHECK if needed to detect that.
  require B;
  my $started = !B::main_start()->isa(q[B::NULL]);
  unless ($started) {
    eval 'CHECK { $started = 1 }; 1'
      or die $@;
  }
  eval 'sub in_global_destruction () { $started && B::main_start()->isa(q[B::NULL]) }; 1'
    or die $@;
}

1;  # keep require happy


__END__

=head1 NAME

Devel::GlobalDestruction - Expose the flag which marks global
destruction.

=head1 SYNOPSIS

    package Foo;
    use Devel::GlobalDestruction;

    use namespace::clean; # to avoid having an "in_global_destruction" method

    sub DESTROY {
        return if in_global_destruction;

        do_something_a_little_tricky();
    }

=head1 DESCRIPTION

Perl's global destruction is a little tricky to deal with WRT finalizers
because it's not ordered and objects can sometimes disappear.

Writing defensive destructors is hard and annoying, and usually if global
destruction is happenning you only need the destructors that free up non
process local resources to actually execute.

For these constructors you can avoid the mess by simply bailing out if global
destruction is in effect.

=head1 EXPORTS

This module uses L<Sub::Exporter::Progressive> so the exports may be renamed,
aliased, etc. if L<Sub::Exporter> is present.

=over 4

=item in_global_destruction

Returns true if the interpreter is in global destruction. In perl 5.14+, this
returns C<${^GLOBAL_PHASE} eq 'DESTRUCT'>, and on earlier perls, it returns the
current value of C<PL_dirty>.

=back

=head1 AUTHORS

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

Jesse Luehrs E<lt>doy@tozt.netE<gt>

Peter Rabbitson E<lt>ribasushi@cpan.orgE<gt>

Arthur Axel 'fREW' Schmidt E<lt>frioux@gmail.comE<gt>

Elizabeth Mattijsen E<lt>liz@dijkmat.nlE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008 Yuval Kogman. All rights reserved
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut
