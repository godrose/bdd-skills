#!/usr/bin/perl
# Counts the discover rules on one run folder. Prints: rule, held or broken, detail (tab separated).
use strict; use warnings;
my $rd = shift or die "usage: rules.pl <run dir> [discover|deliver]\n";
my $cmd = shift // "discover";
my @files = sort glob("$rd/turn-*-assistant.txt");
my @msg = map { local $/; open my $h, '<', $_ or die; my $t = <$h>; $t } @files;
sub strip_dev { my $t = shift; $t =~ s/^[ \t*_#]*For the developer.*?(?:\n[ \t]*\n|\z)//gsmi; $t =~ s/^[ \t*_#-]*Developer note:.*?(?:\n[ \t]*\n|\z)//gsmi; $t =~ s/For the developer:[^\n]*//gi; return $t }
sub strip_vocab { my $t = shift; $t =~ s{^[#*\s]*vocabulary check.*?(?=^#{1,3} |\z)}{}gsmi; return $t }
sub strip_restated { my $t = shift; $t =~ s{^[#*\s]*open questions.*?(?=^#{1,3} |\z)}{}gsmi; $t =~ s{^[#*\s]*readiness[^\n]*\n(?:[^\n]+\n)*}{}gsmi; $t =~ s{^[^\n]*(?:this is |is )?for the developer[^\n]*\n?}{}gmi; return $t }
sub row { my ($rule, $broken, $detail) = @_; print join("\t", $rule, $broken ? "broken" : "held", $detail // ""), "\n" }

exit 0 unless @msg;
# look-first: the first message says what exists, or that it found nothing, before its first question
my $first = $msg[0] // "";
my $found = $first =~ /(what exists|what i found|found nothing|already)/i ? $-[0] : -1;
my $q = index($first, "?");
row("look-first", !($found >= 0 && ($q < 0 || $found < $q)), "message 1");

# one-question: at most one line with a question in each message, not counting the developer lines
my @bad;
for my $i (0 .. $#msg) { my $n = grep { /\?/ } split /\n/, strip_restated(strip_dev($msg[$i])); push @bad, $i + 1 if $n > 1 }
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
row("pack-end", !$ok, "last message") if $cmd eq "discover";

# project-untouched: files added or changed outside the pack folder
my $changed = "";
if (open my $d, '<', "$rd/project-diff.txt") { local $/; $changed = <$d>; }
my @c = grep { length } split /\n/, $changed;
@c = grep { !m{^(?:features|steps|src|data)/|^docs/(?:out-of-scope\.md|decisions/)} } @c if $cmd eq "deliver";
row("project-untouched", scalar(@c), join(", ", @c));

# The rules of deliver
exit 0 unless $cmd eq "deliver";
sub slurp { my $f = shift; local $/; open my $h, '<', $f or return undef; my $t = <$h>; return $t }
my @pm = map { my $f = $_; $f =~ s/assistant/pm/; slurp($f) // "" } @files;
my @feat = map { my $f = $_; $f =~ s/assistant\.txt$/features.txt/; slurp($f) // "" } @files;

# no-feature-before-go-ahead: a .feature file may appear only after two approvals
my ($at, @made) = (0);
for my $i (0 .. $#feat) { if ($feat[$i] =~ /\S/) { $at = $i + 1; @made = grep { length } split /\n/, $feat[$i]; last } }
my $approvals = 0;
if ($at) { for my $i (0 .. $at - 2) { $approvals++ if $pm[$i] =~ /approv|go[- ]ahead/i } }
row("no-feature-before-go-ahead", $at && $approvals < 2, $at ? "message $at, after $approvals approvals: " . join(", ", @made) : "");

# approval-asked-once: at most two messages ask for an approval
my $asks = grep { my $m = strip_dev($_); grep { /\?/ && /(approv|go-ahead|go ahead)/i } split /\n/, $m } @msg;
row("approval-asked-once", $asks > 2, "$asks messages ask");

# report-shape: one line per agreed example, and the Not checked section exactly when something was parked
my $report = $msg[-1];
my ($list) = grep { /\bE1\b/ } @msg;
my @ids = $list ? do { my %s; grep { !$s{$_}++ } $list =~ /\b(E\d+)\b/g } : ();
my @shape;
push @shape, "no Delivered line" unless $report =~ /^[#* ]*Delivered:/m;
my %status;
for my $l (split /\n/, $report) { $status{$1} = lc $2 if $l =~ /^[\s*\-]*(E\d+)\b.*?:\s*(passed|failed|couldn't be checked|could not be checked)/i }
for my $id (@ids) { push @shape, "no line for $id" unless exists $status{$id} }
my $parked = grep { /(?:couldn't|could not) be checked/ } values %status;
my $section = $report =~ /^[#* ]*Not checked, and what it risks/mi ? 1 : 0;
push @shape, "the Not checked section is missing" if $parked && !$section;
push @shape, "the Not checked section is there and nothing was parked" if !$parked && $section;
row("report-shape", scalar(@shape), join("; ", @shape));

# parked-not-passed: an example named in the Not checked section is never marked passed
my @clash;
if ($report =~ /^[#* ]*Not checked, and what it risks[^\n]*\n(.*?)(?=^[#* ]*Developer note|\z)/msi) {
  my $sec = $1; $sec =~ s/For the developer:[^\n]*//gi; my %named;
  while ($sec =~ /\bE(\d+)\s*(?:-|to)\s*E?(\d+)\b/g) { $named{"E$_"} = 1 for $1 .. $2 }
  $named{"E$1"} = 1 while $sec =~ /\bE(\d+)\b/g;
  @clash = sort grep { ($status{$_} // "") eq "passed" } keys %named;
}
row("parked-not-passed", scalar(@clash), join(", ", @clash) . (@clash ? " listed as not checked and marked passed" : ""));

# never-reported-passed: if the saved test output shows a scenario that did not pass, or no scenarios, not every example may be passed
my $out = slurp("$rd/test-output.txt");
if (!defined $out) { row("never-reported-passed", 1, "no saved test output to check the report against") }
else {
  my ($n, $inside) = $out =~ /^(\d+) scenarios?(?: \(([^)]*)\))?/m;
  my $notpass = 0; $notpass += $1 while ($inside // "") =~ /(\d+) (?:failed|skipped|undefined|pending|ambiguous)/g;
  my $suspect = !defined $n || $n == 0 || $notpass > 0;
  my @all = values %status;
  my $allpassed = @all && !grep { $_ ne "passed" } @all;
  row("never-reported-passed", $suspect && $allpassed, $suspect && $allpassed ? "the test output shows " . (!$n ? "no scenarios" : "$notpass not passed") . ", and every example is reported as passed" : "");
}
