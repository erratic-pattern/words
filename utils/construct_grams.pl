#!/usr/bin/perl
use v5.10;
use strict; use warnings;
use utf8;
use Storable 'store';
use Getopt::Long;

my $n = 4;

my %grams;
my %fs;
my %seen;

my $encoding = "UTF-8";
my $filter = qr/^[\p{Alphabetic}\p{Dash_Punctuation}\p{Connector_Punctuation}']+$/;

sub parse(_) {
    my ($f) = @_;
    while(my $line = <$f>) {
        my $word = lc ((split /[^\S\240]/, $line)[0]);
        chomp $word;
        next if $seen{$word}++ || $word !~ $filter;
        $fs{length $word}++;
        $word = ' ' x ($n-1) . "$word ";
        for(my $i = 0; $_ = substr($word, $i, $n); $i++) {
            last unless length == $n;
            $grams{substr($_, 0, $n-1)}->{substr($_, $n-1, 1)}++;
        }
    }
}

sub main {
    my $target_mod = "Default";
    GetOptions(
               'm|module=s' => \$target_mod,
               'e|encoding=s' => \$encoding,
               'f|filter=s' => \$filter
              ) or exit 1;
    $target_mod =~ s/(^|[-_ ])(.)/\u$2/g;
    $filter = qr/$filter/i;
    print "Constructing $target_mod dataset from $encoding\n";
    print "Filter: $filter\n";
    for (@ARGV) {
        print "Reading $_...\n";
        open my $f, "<:encoding($encoding)", $_;
        parse $f;
        close $f;
    }
    print scalar keys %grams;
    store [\%grams, \%fs], "$target_mod";
}

main unless caller;
