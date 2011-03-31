#!/usr/bin/env perl
# (c) 2011 Stephane Alnet
# Licencse: AGPL3+
# A web proxy for TNS's ENUM CNAM implementation.
use strict; use warnings;

use URI::Escape;
use AnyEvent;
use AnyEvent::HTTPD;
use AnyEvent::DNS;

use constant HOST => '127.0.0.1';
use constant PORT => 8091;

my $httpd = AnyEvent::HTTPD->new (
  host => HOST,
  port => PORT,
  request_timeout => 0.5,
  allowed_methods => ['GET'],
);

$httpd->reg_cb(
  '' => sub {
     my ($httpd,$req) = @_;

     if($req->url !~ m{^/(1[2-9]\d\d[2-9]\d\d\d{4})$}) {
        return $req->respond([404,'Invalid URL']);
     }
     my $number = $1;

     my $qname = join( '.', reverse(split(//,$number)) ).'.';
     my $qtype = 'naptr';

     AnyEvent::DNS::resolver->resolve( $qname => $qtype, sub {
       for my $record (@_) {
         my ($name, $type, $class, @data) = @$record;
         # next unless $name eq $qname && $type eq $qtype;
         my ($order,$pref,$flags,$service,$regexp,$replacement) = @data;
         if($regexp =~ m{,([^!]+)!$}) {
           my $text = uri_unescape($1);
           return $req->respond({ content => ['text/plain', $text ]});
         }
       }
       $req->respond([501,'Query error']);
       $httpd->stop_request;
     });

  },
);

$httpd->run;
