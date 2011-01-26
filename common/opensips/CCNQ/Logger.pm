package CCNQ::Logger;

sub warning { print STDERR "Warning: ".join(' ',@_) }
sub error   { print STDERR "Error: ".join(' ',@_) }

@EXPORT = qw( &warning &error );
