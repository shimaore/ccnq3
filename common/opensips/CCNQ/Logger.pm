package CCNQ::Logger;
use strict; use warnings;
use Exporter;
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = '0.1';
@ISA = qw(Exporter);

sub info    { print STDERR "Info: ".join(' ',@_,)."\n" }
sub warning { print STDERR "Warning: ".join(' ',@_)."\n" }
sub error   { print STDERR "Error: ".join(' ',@_)."\n" }

@EXPORT = qw( &info &warning &error );
