// Writes the report for one fixture: counts per rule out of the runs, the breaks, and turns, time and usage. No verdict.
// Usage: report.ts <base dir> <fixture> <runs> <turn cap> [command] [story]
import fs from "node:fs";

const [base, fixture, runs, cap, cmdArg, story] = process.argv.slice(2);
const cmd = cmdArg ?? "discover";

const slurp = (f: string): string | undefined => { try { return fs.readFileSync(f, "utf8"); } catch { return undefined; } };

// printf %.3f rounds an exact tie to even, toFixed rounds it up
function fixed3(x: number): string {
  const s = x * 1000;
  if (Number.isFinite(s) && s % 1 === 0.5) { const n = Math.floor(s); return ((n % 2 === 0 ? n : n + 1) / 1000).toFixed(3); }
  return x.toFixed(3);
}

const held = new Map<string, number>();
const breaks = new Map<string, string[]>();
const order: string[] = [];
const rows: [number, string | undefined, string | undefined, string | undefined, string | undefined][] = [];
const noans: string[] = [];
let scored = 0;

for (let i = 1; i <= Number(runs); i++) {
  const rd = `${base}/run-${i}`;
  const tsv = slurp(`${rd}/rules.tsv`);
  if (tsv === undefined) continue;
  if (tsv.length === 0) { noans.push(`run-${i}`); continue; }
  scored++;
  const lines = tsv.split("\n");
  if (lines[lines.length - 1] === "") lines.pop();
  for (const line of lines) {
    const [rule, st, ...rest] = line.split("\t");
    const detail = rest.join("\t");
    if (!order.includes(rule)) order.push(rule);
    if (st === "held") held.set(rule, (held.get(rule) ?? 0) + 1);
    else breaks.set(rule, [...(breaks.get(rule) ?? []), `run-${i}: ${detail}`]);
  }
  const meta = slurp(`${rd}/meta.json`);
  if (meta === undefined) continue;
  rows.push([i, meta.match(/"turns":\s*(\d+)/)?.[1], meta.match(/"seconds":\s*(\d+)/)?.[1], meta.match(/"cost_usd":\s*([\d.e+-]+)/)?.[1], meta.match(/"finished":\s*(\w+)/)?.[1]]);
}

let out = `# Flow report: ${cmd}, fixture ${fixture}${(story ?? "").length ? `, story ${story}` : ""}\n\n`;
out += `Runs: ${runs}. Turn cap: ${cap}. Counts only: this report gives no verdict.\n\n`;
out += "| Rule | Runs that held it |\n|---|---|\n";
for (const r of order) out += `| ${r} | ${held.get(r) ?? 0} of ${scored} |\n`;
out += "\n## Breaks\n\n";
let any = false;
for (const r of order) for (const b of breaks.get(r) ?? []) { out += `- ${r}, ${b}\n`; any = true; }
if (!any) out += "None.\n";
out += "\n## Runs\n\n| Run | turns | seconds | Usage (USD, notional) | Finished |\n|---|---|---|---|---|\n";
for (const [i, t, s, c, f] of rows) out += `| run-${i} | ${t ?? ""} | ${s ?? ""} | ${fixed3(Number(c ?? 0))} | ${f ?? "false"} |\n`;
const unfinished = rows.filter((r) => (r[4] ?? "false") !== "true").map((r) => `run-${r[0]}`);
if (noans.length) out += `\n${noans.join(", ")} had no answer from claude, so they are not scored.\n`;
if (unfinished.length) out += `\n${unfinished.join(", ")} did not finish: the pack never stated its readiness before the cap or an error.\n`;
process.stdout.write(out);
