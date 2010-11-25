#!/usr/bin/env perl
use strict; use warnings;

use Cache::Memcached;

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

  my $cache = Cache::Memcached->new(servers => '127.0.0.1:11211');

  my $httpd = AnyEvent::HTTPD->new (
    host => $config->{httpd_host},
    port => $config->{httpd_port},
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

      $req->respond([200,'OK',{ 'Content-Type' => 'application/json' }, encode_json($data)]);
    },
  );

  $httpd->run;
}

run(@ARGV);