// Puts the rule counts of two reports side by side and marks the rules that moved. No verdict.
// Usage: compare.ts <first report> <second report>
import fs from "node:fs";

const [fa, fb] = process.argv.slice(2);

function counts(f: string): [Map<string, string>, string[]] {
  let text: string;
  try { text = fs.readFileSync(f, "utf8"); } catch { process.stderr.write(`cannot read ${f}\n`); process.exit(1); }
  const c = new Map<string, string>();
  const order: string[] = [];
  for (const line of text.split("\n")) {
    const m = line.match(/^\|\s*([a-z][a-z-]*)\s*\|\s*(\d+ of \d+)\s*\|/);
    if (m) { order.push(m[1]); c.set(m[1], m[2]); }
  }
  return [c, order];
}

const [ca, oa] = counts(fa);
const [cb, ob] = counts(fb);
const rules = [...oa];
for (const r of ob) if (!rules.includes(r)) rules.push(r);
let out = "| Rule | First report | Second report | |\n|---|---|---|---|\n";
for (const r of rules) {
  const [x, y] = [ca.get(r) ?? "-", cb.get(r) ?? "-"];
  out += `| ${r} | ${x} | ${y} | ${x === y ? "" : "moved"} |\n`;
}
process.stdout.write(out);
