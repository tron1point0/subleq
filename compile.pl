#!/usr/bin/env perl

use v5.16;
use warnings;

use Data::Dump qw(pp);

my $size = 0xFF;
my $head = "v2.0 raw\n";

my %sym = (
    Z => $size - 1,
);

my %isa;
%isa = (
    subleq => sub {
        my ($a,$b,$c) = @_;
        $c //= 0x01;
        [$a,$b,$c]
    },
    add => sub {
        my ($a,$b,$c) = @_;
        $isa{subleq}->($a,'Z'),
        $isa{subleq}->('Z',$b),
        $isa{subleq}->('Z','Z',$c)
    },
    mov => sub {
        my ($a,$b,$c) = @_;
        $isa{subleq}->($b,$b),
        $isa{add}->($a,$b,$c)
    },
    jmpr => sub {
        my ($a) = @_;
        $isa{subleq}->('Z','Z',$a);
    },
    jmp => sub {
        my ($a) = @_;
        sub {
            my ($i) = @_;
            $isa{jmpr}->(($a-$i+1) % 0xFF)
        }
    },
    halt => sub {
        $isa{jmp}->($size);
    },
);

sub expand {
    my ($fn,@args) = split;
    return $isa{$fn}->(@args) if defined $isa{$fn};
    $_
}

my @lines = map {
    chomp;
    s/#.*//g;
    s/^\s*//;
    s/\s*$//;
    $_ ? expand : ()} <>;

my $ins = 0;
for (@lines) {
    next unless $_;
    $sym{$1} = $ins, redo if !ref $_ and
        s/^\s*(\w+):\s*// ||
        s/^\s*\.(\w+)\s*//;
    $ins++;
}

@lines = grep {$_} @lines;

$sym{Z} = @lines;

$ins = 0;
@lines = map {
    $ins++;
    $_ = $_->($ins) if ref $_ eq ref sub {};
    $_ = [map {defined $sym{$_} ? $sym{$_} : $_} @$_] if ref $_ eq ref [];
    $_ = ($_->[0] << 16) + ($_->[1] << 8) + $_->[2] if ref $_ eq ref [];
    $_ = hex $_ if /^0x\d+$/;
    $_
} @lines;

$ins = 0;
say 'v2.0 raw';
printf "%06x".(++$ins % 8 == 0 ? "\n" : ' '), $_ for @lines;
say '' if $ins % 8 > 0;
