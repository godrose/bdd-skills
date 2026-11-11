#!/usr/bin/perl
# Puts the rule counts of two reports side by side and marks the rules that moved. No verdict.
use strict; use warnings;
my ($fa, $fb) = @ARGV;
sub counts {
  my $f = shift; my (%c, @o);
  open my $h, '<', $f or die "cannot read $f\n";
  while (<$h>) { if (/^\|\s*([a-z][a-z-]*)\s*\|\s*(\d+ of \d+)\s*\|/) { push @o, $1; $c{$1} = $2 } }
  return (\%c, \@o);
}
my ($ca, $oa) = counts($fa); my ($cb, $ob) = counts($fb);
my @rules = @$oa; for my $r (@$ob) { push @rules, $r unless grep { $_ eq $r } @rules }
print "| Rule | First report | Second report | |\n|---|---|---|---|\n";
for my $r (@rules) {
  my ($x, $y) = ($ca->{$r} // "-", $cb->{$r} // "-");
  printf "| %s | %s | %s | %s |\n", $r, $x, $y, $x eq $y ? "" : "moved";
}
