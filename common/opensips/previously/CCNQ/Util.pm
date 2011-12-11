package CCNQ::Util;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;
use CCNQ::Logger;
use Carp qw(croak);

=head1 DESCRIPTION

=head2 first_line_of($filename)

Returns the first line of the file $filename,
or undef if an error occurred.

=cut

sub first_line_of {
  open(my $fh, '<:utf8', $_[0]) or error("$_[0]: $!"), return undef;
  my $result = <$fh>;
  chomp($result);
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=head2 content_of($filename)

    Returns the content of file $filename,
    or undef if an error occurred.

=cut

sub content_of {
  open(my $fh, '<:utf8', $_[0]) or error("$_[0]: $!"), return undef;
  local $/;
  my $result = <$fh>;
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=head2 lines_of($filename)

    Read all lines from the file and returns them as an arrayref.

=cut

sub lines_of {
  open(my $fh, '<:utf8', $_[0]) or error("$_[0]: $!"), return undef;
  my @lines = ();
  while(<$fh>) {
    chomp;
    push @lines, $_;
  }
  close($fh) or error("$_[0]: $!"), return undef;
  return [@lines];
}


=head2 print_to($filename,$content)

Saves the $content to the specified $filename.
croak()s on errors.

=cut

sub print_to {
  open(my $fh, '>:utf8', $_[0]) or croak "$_[0]: $!";
  print $fh $_[1];
  close($fh) or croak "$_[0]: $!";
}

=head2 execute($command,@parameters)

A fancy version of system() with error handling and logging.

This version of execute() is synchronous / blocking, and suitable
only for use in install blocks.

=cut

sub execute {
  my $command = join(' ',@_);

  my $ret = system(@_);
  # Happily lifted from perlfunc.
  if ($ret == -1) {
      error("Failed to execute ${command}: $!");
  }
  elsif ($ret & 127) {
      error(sprintf "Child command ${command} died with signal %d, %s coredump",
          ($ret & 127),  ($ret & 128) ? 'with' : 'without');
  }
  else {
      info(sprintf "Child command ${command} exited with value %d", $ret >> 8);
  }
  return 0;
}

1;
