#!/usr/bin/env perl
use 5.22.0;
use warnings;
use utf8;
use FindBin '$Bin';
use lib "$Bin/lib";
use IO::Socket::SSL;
use AnySan::Provider::Twitter;
use AnySan;
use Config::Pit;
use Util qw(slack_unescape perl6_eval perl6_version);

my $username = shift;

if (!$username) { die "please input your twitter name" };

my $config = pit_get("api.twitter.com", require => {
    consumer_key    => 'your twitter consumer_key',
    consumer_secret => 'your twitter consumer_secret',
    token           => 'your twitter access_token',
    token_secret    => 'your twitter access_token_secret',
  });

my $twitter = twitter(
%{ $config },
method          => 'userstream',
)
;

AnySan->register_listener(
  acotie => {
    event => 'timeline',
    cb => sub {
      my $receive = shift;
      return unless $receive->from_nickname;
      return unless $receive->message;
      return unless $receive->message =~ /^\@$username\s*(.+)$/;
      my $program = $1;
      $program = $1 if $program =~ /\A`(.+)`\z/;
      $program = slack_unescape $1;
      my $out = perl6_eval $program;
      
      my $message = sprintf '@%s %s', $receive->from_nickname, $out;
      
      if ( length($message) > 140 ) {
        $message = substr($message, 0, 130) . "...";
      }
      
      $receive->send_reply(
        $message
      );
    },
  },
);

AnySan->run;
