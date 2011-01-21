#!/usr/bin/env perl
# dsmlayer: a web proxy for Perl's DBI
# Copyright (c) 2010  Stephane Alnet
# License: Affero GPL 3+

use strict; use warnings;

use Cache::Memcached;

# required to thaw the response
use Dancer::Session::Memcached;

use AnyEvent;
use AnyEvent::HTTPD;

use Encode;
use JSON;
use URI;
use Data::Structure::Util qw(unbless);


sub config {
  my ($name) = @_;
  $name or die "$0 <configfile>";
  open(my $fh, '<:utf8', $name) or die $!;
  local $/;
  my $json = <$fh>;
  close($fh);
  return decode_json($json);
}

sub run {
  my $config = config(@_);

  my $cache = Cache::Memcached->new(servers => ['127.0.0.1:11211']);

  my $httpd = AnyEvent::HTTPD->new (
    host => $config->{httpd_host},
    port => $config->{httpd_port},
    request_timeout => 3,
  );

  $httpd->reg_cb(
    '' => sub {
      my ($httpd,$req) = @_;

      my $error = sub {
        my ($code,$msg,$params) = @_;
        $code ||= 500;
        $msg ||= 'Internal error';
        $params ||= '';
        my $response = {
          error=>$msg,
          info=>$params
        };
        $req->respond([$code,$msg,{ 'Content-Type' => 'application/json' }, encode_json($response)]);
        $httpd->stop_request;
        return;
      };

      my $url = URI->new($req->url);
      my $path = $url->path;

      my ($id) = ($path =~ m{^/(.+)$}) or return $error->(404,'Not found');

      my $data = $cache->get($id);
      $data or return $error->(404,'No such session');

      my $json = eval { encode_json(unbless($data)) };
      $@   and return $error->(500,'Data error',$@);
      $json or return $error->(500,'Data error');

      $req->respond([200,'OK',{ 'Content-Type' => 'application/json' },$json]);
    },
  );

  $httpd->run;
}

run(@ARGV);