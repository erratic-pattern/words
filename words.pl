#!/usr/bin/perl
use strict; use warnings;
use v5.10;
use open qw( :encoding(UTF-8) :std);
use File::Basename 'dirname';
use Storable 'retrieve';
use List::Util qw(sum min);
use Getopt::Long qw(:config gnu_getopt);
BEGIN {
    eval {
        require Math::Random::MT::Perl; Math::Random::MT::Perl->import('rand');
    };
    #warn "Optional module Math::Random::MT::Perl not found.\n" if $@;
}

#constants
my @options = qw(eng-1M eng-all eng-fiction eng-gb eng-us french german hebrew russian spanish irish german-medical bulgarian catalan swedish brazilian canadian-english-insane manx italian ogerman portuguese polish gaelic finnish norwegian);
my $n = 4;
my $default_opt     = "--eng-1M";
(my $default_dataset = $default_opt) =~ s/(^|-+)([^-])/\u$2/g;

#help info
my $help_text = <<END
Usage: words [-dhNo] [DATASETS...] [NUMBER_OF_WORDS]

options:
  -l, --list             list valid datasets
  -d, --debug            debugging output
  -N, --dont-normalize   don't normalize frequencies when combining
                         multiple Markov models; this has the effect
                         of making larger datasets more influential
  -o, --target-offset    change the target length offset used in the
                         word generation algorithm; use negative integers
                         for best results
END
;

my $list_text = <<END
valid datasets: --@{[join ' --', @options]}
default: $default_opt
END
;

#data from loaded files
my @loaded_data;

#data after normalizing and combining datasets
my $grams;
my $freqs;

#some command line options
my $debug_mode;
my $target_offset = -4; #needs testing;
my $dont_normalize;

sub pick(%) {
    my ($f) = @_;
    my @c = keys %$f;
    my @w = map { $f->{$_} } @c;
    my $r = rand(sum(@w));
    for(0..$#c) {
        return $c[$_] if $r < $w[$_];
        $r -= $w[$_];
    }
    print "end of pick loop reached. returned $c[$#w]\n" if $debug_mode;
    return $c[$#w];
}

sub get_gram {
    my ($key) = @_;
    ##Lazily interpolate the gram table on the fly
    ##then cache the results
    unless (defined $grams->{$key}) {
        for(@loaded_data) {
            my $data = $_->[0];
            my $g = $data->{$key} or next;
            my $sum = $dont_normalize || sum(values %$g);
            while( my ($c, $v) = each %$g ) {
                $grams->{$key}->{$c} += $v/$sum;
            }
        }
    }
    return $grams->{$key};
}

sub generate {
    my $target = pick($freqs) + $target_offset;
    my $word = ' ' x ($n-1);
    my $c;
    do {
        my $len = (length $word) - ($n-1);
        my %ftable = %{get_gram substr($word, -$n+1, $n-1)};
        ($ftable{' '} //= 0) *= 2**($len-$target);
        $c = pick \%ftable;
        $word .= $c;
    } while $c ne ' ';
    $word =~ s/\s//g;
    $word = "$word (L-T: @{[length($word) - $target]})" if $debug_mode;
    return $word;
}

sub load_dataset {
    my ($mod) = @_;
    push @loaded_data, retrieve ("data/$mod") or die "Unable to load $mod";
}

sub main {
    if (my $d = dirname $0) { chdir $d }
    ##Option handling
    my ($help_mode, $list_mode);
    @ARGV = split /\s+/, $ARGV[0] if @ARGV == 1;
    GetOptions (
                'd|debug'            => \$debug_mode,
                'h|help'             => \$help_mode,
                'l|list'             => \$list_mode,
                'N|dont-normalize'   => \$dont_normalize,
                'o|target-offset=s'  => \$target_offset,
                map {
                    my $mod=$_;
                    $mod =~ s/(^|-)(.)/\u$2/g;
                    $_, sub { load_dataset $mod };
                } @options
               ) or exit 1;
    return print $help_text if $help_mode;
    return print $list_text if $list_mode;
    ##Use the default dataset if no others were specified
    load_dataset $default_dataset unless @loaded_data;
    ##In the case of 1 dataset, skip normalization by copying everything
    ##into the tables
    if (@loaded_data == 1) {
        ($grams, $freqs) = @{$loaded_data[0]};
    }
    ##Otherwise, normalize and combine the length histograms.
    ##The gram tables will be normalized lazily as needed (see: get_gram)
    else {
        for (@loaded_data) {
            my $fdata = $_->[1];
            my $sum = $dont_normalize || sum(values %$fdata);
            while ( my ($len, $f) = each %$fdata ) {
                $freqs->{$len} += $f/$sum;
            }
        }
    }

    ##Run word generator and print results
    {
        local $\ = ' ';
        print generate for 1..min(25, int($ARGV[0]||1));
    }
    print "\n";
    return 0;
}

exit main unless caller;
1;
