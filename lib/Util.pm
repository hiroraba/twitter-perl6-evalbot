package Util;
use strict;
use warnings;
use utf8;
use 5.22.0;
use HTTP::Tiny;
use JSON::PP;
use IO::Socket::SSL;
use EvalbotExecuter;
use Exporter 'import';
our @EXPORT_OK = qw(slack_unescape perl6_eval perl6_version);

sub slack_unescape {
    my $decoded = shift;
    state $unescape = sub {
        my $seq = shift;
        if    ($seq =~ s/^#C//)  { $seq =~ s/.*\|//; "#C$seq"  }
        elsif ($seq =~ s/^\@U//) { $seq =~ s/.*\|//; "\@$seq" }
        elsif ($seq =~ s/!//)    { $seq =~ s/.*\|//; "\@$seq"  }
        else                     { $seq =~ s/.*\|//; $seq     }
    };

    $decoded =~ s/<(.*?)>/ $unescape->($1) /eg;
    $decoded =~ s/&amp;/&/g;
    $decoded =~ s/&lt;/</g;
    $decoded =~ s/&gt;/>/g;
    $decoded;
}

sub format_output {
    my $response = shift;
    return "(no output)\n" unless length $response;

    my $newline = '␤';
    my $null    = "\N{SYMBOL FOR NULL}";
    $response =~ s/\n/$newline/g;
    $response =~ s/\x00/$null/g;

    return "$response\n";
}

sub perl6_eval {
    my $str = shift;
    my $perl6 = {
        cmd_line => q{RAKUDO_ERROR_COLOR= perl6 --setting=RESTRICTED %program},
    };

    # NOTE: result is decoded
    my $result = EvalbotExecuter::run($str, $perl6, "perl6");
    $result =~ s{/var/folders/[a-z0-9_/-]+}{/var/tempfile}gi;
    $result =~ s{/tmp/\S{10}}{/tmp/tempfile}g;
    format_output($result);
}

sub perl6_version {
    my $out = `perl6 -v` || '(something wrong)';
    $out;
}

1;
