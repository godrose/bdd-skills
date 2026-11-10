#!/usr/bin/perl
# Counts the discover rules on one run folder. Prints: rule, held or broken, detail (tab separated).
use strict; use warnings;
my $rd = shift or die "usage: rules.pl <run dir>\n";
my @files = sort glob("$rd/turn-*-assistant.txt");
my @msg = map { local $/; open my $h, '<', $_ or die; my $t = <$h>; $t } @files;
sub strip_dev { my $t = shift; $t =~ s/^[ \t*_#]*For the developer.*?(?:\n[ \t]*\n|\z)//gsmi; return $t }
sub strip_vocab { my $t = shift; $t =~ s{^[#*\s]*vocabulary check.*?(?=^#{1,3} |\z)}{}gsmi; return $t }
sub row { my ($rule, $broken, $detail) = @_; print join("\t", $rule, $broken ? "broken" : "held", $detail // ""), "\n" }

exit 0 unless @msg;
# look-first: the first message says what exists, or that it found nothing, before its first question
my $first = $msg[0] // "";
my $found = $first =~ /(what exists|what i found|found nothing|already)/i ? $-[0] : -1;
my $q = index($first, "?");
row("look-first", !($found >= 0 && ($q < 0 || $found < $q)), "message 1");

# one-question: at most one line with a question in each message, not counting the developer lines
my @bad;
for my $i (0 .. $#msg) { my $n = grep { /\?/ } split /\n/, strip_dev($msg[$i]); push @bad, $i + 1 if $n > 1 }
row("one-question", scalar(@bad), join(", ", map { "message $_" } @bad));

# plain-words: no file path, file name or code span outside the developer lines
my @pw;
for my $i (0 .. $#msg) {
  my $t = strip_vocab(strip_dev($msg[$i]));
  $t =~ s/`?bdd:\w+`?//g; $t =~ s{`?docs/discovery/?`?}{}g;
  push @pw, $i + 1 if $t =~ /`[^`\n]*(?:[A-Z]{2,}_|_[A-Za-z]|[a-z][A-Z]|\(\)|\w\.\w+\()[^`\n]*`/ || $t =~ m{[\w.-]+(?:/[\w.-]+)+\.\w{1,5}\b} || $t =~ /\b[\w-]+\.(?:js|ts|cs|py|feature|json|yml|yaml|sh|html)\b/;
}
row("plain-words", scalar(@pw), join(", ", map { "message $_" } @pw));

# pack-end: the last message has a readiness line, a verdict and a reason
my $last = $msg[-1] // "";
my $ok = 0;
if ($last =~ /^([#*\s]*readiness.*)\z/smi) {
  my $sec = $1; $sec =~ s/^[#*\s]*readiness[:*\s\-]*//i;
  if ($sec =~ /\b(not ready|ready)\b[ \t:.\-]*([^\n]*)((?:\n.*)?)/i) {
    my ($tail, $more) = ($2, $3);
    my @w = split ' ', $tail; $ok = 1 if $sec !~ /\bnot ready\b/i || @w >= 3 || $more =~ /\S/;
  }
}
row("pack-end", !$ok, "last message");

# project-untouched: files added or changed outside the pack folder
my $changed = "";
if (open my $d, '<', "$rd/project-diff.txt") { local $/; $changed = <$d>; }
my @c = grep { length } split /\n/, $changed;
row("project-untouched", scalar(@c), join(", ", @c));
