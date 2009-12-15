#!/usr/bin/env perl
use warnings;
use strict;
use v5.10;

@ARGV or die "Usage: $0 extension [paths] {options}";
my $ext = shift;
my @paths = grep !/^-/, @ARGV;

use List::AllUtils qw/any/;
use Getopt::Casual;
if (not grep defined, @ARGV{qw/--ext-eq-magic --ext-ne-magic --magic-ne-ext/}
or $ARGV{"--all"}) {
    $ARGV{$_} = 1 for qw/--ext-eq-magic --ext-ne-magic --magic-ne-ext/;
}

use File::Find::Rule;
use File::MimeInfo::Magic qw/magic extensions/;

sub contains {
    my $v = lc shift;
    any { $v eq $_ } map lc, grep defined, @_;
}

sub magics {
    magic(shift || $_) || "unknown";
}

sub ext_matches {
    contains $ext, extensions(magics shift);
}

if ($ARGV{"--ext-eq-magic"}) {
    print "Files which have the $ext extension and magic number:\n";
    print "    $_\n" for File::Find::Rule
        ->file()
        ->name(qr/\.\Q$ext\E$/i)
        ->exec(sub { ext_matches($_) })
        ->in(@paths);
}

if ($ARGV{"--ext-ne-magic"}) {
    print "Files which have the $ext extension and a different magic number:\n";
    print "    $_ (", magics, ")\n" for File::Find::Rule
        ->file()
        ->name(qr/\.\Q$ext\E$/i)
        ->exec(sub { not ext_matches($_) })
        ->in(@paths);
}

if ($ARGV{"--magic-ne-ext"}) {
    print "Files which have the $ext magic number, but a different extension:\n";
    print "    $_\n" for File::Find::Rule
        ->file()
        ->exec(sub {
            !/\. \Q$ext\E $/ix
                and
            contains($ext, extensions(magics($_)))
        })
        ->in(@paths);
}
