=head1 NAME

AE::DBI - asynchronous DBI access

=cut

package AE::DBI;

use base qw(AnyEvent::DBI);

sub req_exec {
   my (undef, $st, @args) = @{+shift};
   my $sth = $DBH->prepare_cached ($st, undef, 1)
      or die [$DBI::errstr];

   my $rv = $sth->execute (@args)
      or die [$sth->errstr];

   [1, $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref({}) : undef, $rv]
}

1;

