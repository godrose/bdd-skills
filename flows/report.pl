#!/usr/bin/perl
# Writes the report for one fixture: counts per rule out of the runs, the breaks, and turns, time and usage. No verdict.
use strict; use warnings;
my ($base, $fixture, $runs, $cap) = @ARGV;
my (%held, %breaks, @order, @rows);
for my $i (1 .. $runs) {
  my $rd = "$base/run-$i";
  open my $r, '<', "$rd/rules.tsv" or next;
  while (<$r>) {
    chomp; my ($rule, $st, $detail) = split /\t/, $_, 3;
    push @order, $rule unless grep { $_ eq $rule } @order;
    if ($st eq 'held') { $held{$rule}++ } else { push @{ $breaks{$rule} }, "run-$i: " . ($detail // "") }
  }
  my $meta = do { local $/; open my $m, '<', "$rd/meta.json" or next; <$m> };
  my ($t) = $meta =~ /"turns":\s*(\d+)/; my ($s) = $meta =~ /"seconds":\s*(\d+)/;
  my ($c) = $meta =~ /"cost_usd":\s*([\d.e+-]+)/; my ($f) = $meta =~ /"finished":\s*(\w+)/;
  push @rows, [$i, $t, $s, $c, $f];
}
print "# Flow report: fixture $fixture\n\n";
print "Runs: $runs. Turn cap: $cap. Counts only: this report gives no verdict.\n\n";
print "| Rule | Runs that held it |\n|---|---|\n";
printf "| %s | %d of %d |\n", $_, $held{$_} // 0, $runs for @order;
print "\n## Breaks\n\n";
my $any = 0;
for my $rule (@order) { for my $b (@{ $breaks{$rule} // [] }) { print "- $rule, $b\n"; $any = 1 } }
print "None.\n" unless $any;
print "\n## Runs\n\n| Run | turns | seconds | Usage (USD, notional) | Finished |\n|---|---|---|---|---|\n";
printf "| run-%d | %s | %s | %.3f | %s |\n", @$_[0, 1, 2], $_->[3] // 0, $_->[4] // "false" for @rows;
my @un = map { "run-$_->[0]" } grep { ($_->[4] // "false") ne "true" } @rows;
print "\n", join(", ", @un), " did not finish: the pack never stated its readiness before the cap or an error.\n" if @un;
