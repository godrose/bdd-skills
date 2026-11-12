// Counts the rules on one run folder. Prints: rule, held or broken, detail (tab separated).
// Usage: rules.ts <run dir> [discover|deliver]
import fs from "node:fs";

const rd = process.argv[2];
if (!rd) { process.stderr.write("usage: rules.ts <run dir> [discover|deliver]\n"); process.exit(1); }
const cmd = process.argv[3] ?? "discover";

// Perl semantics kept on purpose: a line starts only after \n, \s is ASCII, \z is the end of the text.
const WS = "\\t\\n\\v\\f\\r ";
const BOL = "(?<![^\\n])";
const EOT = "(?![\\s\\S])";
const rx = (src: string, flags: string): RegExp => new RegExp(src, flags);
const words = (t: string): string[] => t.split(rx(`[${WS}]+`, "")).filter((w) => w.length > 0);

const slurp = (f: string): string | undefined => { try { return fs.readFileSync(f, "utf8"); } catch { return undefined; } };
const files = fs.readdirSync(rd).filter((n) => /^turn-.*-assistant\.txt$/.test(n)).sort().map((n) => `${rd}/${n}`);
const msg = files.map((f) => slurp(f) ?? "");

const stripDev = (t: string): string => {
  t = t.replace(rx(`${BOL}[ \\t*_#]*For the developer.*?(?:\\n[ \\t]*\\n(?:[ \\t]*\\|[^\\n]*(?:\\n|${EOT}))+|\\n[ \\t]*\\n|${EOT})`, "gsi"), "");
  t = t.replace(rx(`${BOL}[ \\t*_#-]*Developer note:.*?(?:\\n[ \\t]*\\n|${EOT})`, "gsi"), "");
  return t.replace(/For the developer:[^\n]*/gi, "");
};
const stripVocab = (t: string): string => t.replace(rx(`${BOL}[#*${WS}]*vocabulary check.*?(?=${BOL}#{1,3} |${EOT})`, "gsi"), "");
const stripRestated = (t: string): string => {
  t = t.replace(rx(`${BOL}[#*${WS}]*open questions.*?(?=${BOL}#{1,3} |${EOT})`, "gsi"), "");
  t = t.replace(rx(`${BOL}[#*${WS}]*readiness[^\\n]*\\n(?:[^\\n]+\\n)*`, "gi"), "");
  return t.replace(rx(`${BOL}[^\\n]*(?:this is |is )?for the developer[^\\n]*\\n?`, "gi"), "");
};

let out = "";
const row = (rule: string, broken: boolean, detail: string): void => { out += [rule, broken ? "broken" : "held", detail].join("\t") + "\n"; };
const flush = (): void => { process.stdout.write(out); };

function count(): void {
  if (msg.length === 0) return;

  // look-first: the first message says what exists, or that it found nothing, before its first question
  const first = msg[0];
  const m = first.match(/(what exists|what i found|found nothing|already|\bi (?:ran|looked|checked|read|searched)\b)/i);
  const found = m ? m.index! : -1;
  const q = first.indexOf("?");
  row("look-first", !(found >= 0 && (q < 0 || found < q)), "message 1");

  // one-question: at most one line with a question in each message, not counting the developer lines
  const bad: number[] = [];
  msg.forEach((t, i) => { if (stripRestated(stripDev(t)).split("\n").filter((l) => /\?/.test(l)).length > 1) bad.push(i + 1); });
  row("one-question", bad.length > 0, bad.map((n) => `message ${n}`).join(", "));

  // plain-words: no file path, file name or code span outside the developer lines
  const pw: number[] = [];
  msg.forEach((raw, i) => {
    let t = stripVocab(stripDev(raw));
    t = t.replace(/`?bdd:\w+`?/g, "").replace(/`?docs\/discovery\/?`?/g, "");
    if (/`[^`\n]*(?:[A-Z]{2,}_|_[A-Za-z]|[a-z][A-Z]|\(\)|\w\.\w+\()[^`\n]*`/.test(t) || /[\w.-]+(?:\/[\w.-]+)+\.\w{1,5}\b/.test(t) || /\b[\w-]+\.(?:js|ts|cs|py|feature|json|yml|yaml|sh|html)\b/.test(t)) pw.push(i + 1);
  });
  row("plain-words", pw.length > 0, pw.map((n) => `message ${n}`).join(", "));

  // pack-end: the last message has a readiness line, a verdict and a reason
  const last = msg[msg.length - 1];
  let ok = false;
  const lm = last.match(rx(`${BOL}([#*${WS}]*readiness[\\s\\S]*)${EOT}`, "i"));
  if (lm) {
    const sec = lm[1].replace(rx(`^[#*${WS}]*readiness[:*${WS}\\-]*`, "i"), "");
    const vm = sec.match(/\b(not ready|ready)\b[ \t:.-]*([^\n]*)((?:\n[^\n]*)?)/i);
    if (vm) {
      const [tail, more] = [vm[2], vm[3]];
      if (!/\bnot ready\b/i.test(sec) || words(tail).length >= 3 || rx(`[^${WS}]`, "").test(more)) ok = true;
    }
  }
  if (cmd === "discover") row("pack-end", !ok, "last message");

  // project-untouched: files added or changed outside the pack folder
  let c = (slurp(`${rd}/project-diff.txt`) ?? "").split("\n").filter((l) => l.length > 0);
  if (cmd === "deliver") c = c.filter((l) => !/^(?:features|steps|src|data)\/|^docs\/(?:out-of-scope\.md|decisions\/)/.test(l));
  row("project-untouched", c.length > 0, c.join(", "));

  if (cmd !== "deliver") return;
  deliverRules();
}

function deliverRules(): void {
  const pm = files.map((f) => slurp(f.replace("assistant", "pm")) ?? "");
  const feat = files.map((f) => slurp(f.replace(/assistant\.txt$/, "features.txt")) ?? "");
  const nonBlank = rx(`[^${WS}]`, "");

  // no-feature-before-go-ahead: a .feature file may appear only after two approvals
  let at = 0;
  let made: string[] = [];
  for (let i = 0; i < feat.length; i++) { if (nonBlank.test(feat[i])) { at = i + 1; made = feat[i].split("\n").filter((l) => l.length > 0); break; } }
  let approvals = 0;
  if (at) for (let i = 0; i <= at - 2; i++) if (/approv|go[- ]ahead/i.test(pm[i])) approvals++;
  row("no-feature-before-go-ahead", at > 0 && approvals < 2, at ? `message ${at}, after ${approvals} approvals: ${made.join(", ")}` : "");

  // approval-asked-once: at most two messages ask for an approval
  const asks = msg.filter((t) => stripDev(t).split("\n").some((l) => /\?/.test(l) && /(approv|go-ahead|go ahead)/i.test(l))).length;
  row("approval-asked-once", asks > 2, `${asks} messages ask`);

  // report-shape: one line per agreed example, and the Not checked section exactly when something was parked
  const report = msg[msg.length - 1];
  const list = msg.find((t) => /\bE1\b/.test(t));
  const ids = list ? [...new Set([...list.matchAll(/\b(E\d+)\b/g)].map((x) => x[1]))] : [];
  const shape: string[] = [];
  if (!rx(`${BOL}[#* ]*Delivered:`, "").test(report)) shape.push("no Delivered line");
  const status = new Map<string, string>();
  for (const l of report.split("\n")) {
    const sm = l.match(rx(`^[${WS}*\\-]*(E\\d+)\\b[^\\n]*?:[${WS}]*(passed|failed|couldn't be checked|could not be checked)`, "i"));
    if (sm) status.set(sm[1], sm[2].toLowerCase());
  }
  for (const id of ids) if (!status.has(id)) shape.push(`no line for ${id}`);
  const parked = [...status.values()].filter((v) => /(?:couldn't|could not) be checked/.test(v)).length;
  const section = rx(`${BOL}[#* ]*Not checked, and what it risks`, "i").test(report);
  if (parked && !section) shape.push("the Not checked section is missing");
  if (!parked && section) shape.push("the Not checked section is there and nothing was parked");
  row("report-shape", shape.length > 0, shape.join("; "));

  // parked-not-passed: an example named in the Not checked section is never marked passed
  let clash: string[] = [];
  const pm2 = report.match(rx(`${BOL}[#* ]*Not checked, and what it risks[^\\n]*\\n([\\s\\S]*?)(?=${BOL}[#* ]*Developer note|${EOT})`, "i"));
  if (pm2) {
    const sec = pm2[1].replace(/For the developer:[^\n]*/gi, "");
    const named = new Set<string>();
    for (const r of sec.matchAll(rx(`\\bE(\\d+)[${WS}]*(?:-|to)[${WS}]*E?(\\d+)\\b`, "gi"))) for (let k = Number(r[1]); k <= Number(r[2]); k++) named.add(`E${k}`);
    for (const r of sec.matchAll(/\bE(\d+)\b/gi)) named.add(`E${r[1]}`);
    clash = [...named].filter((k) => (status.get(k) ?? "") === "passed").sort();
  }
  row("parked-not-passed", clash.length > 0, clash.join(", ") + (clash.length ? " listed as not checked and marked passed" : ""));

  // never-reported-passed: if the saved test output shows a scenario that did not pass, or no scenarios, not every example may be passed
  const saved = slurp(`${rd}/test-output.txt`);
  if (saved === undefined) { row("never-reported-passed", true, "no saved test output to check the report against"); return; }
  const tm = saved.match(rx(`${BOL}(\\d+) scenarios?(?: \\(([^)]*)\\))?`, ""));
  const n = tm ? Number(tm[1]) : undefined;
  let notpass = 0;
  for (const r of (tm?.[2] ?? "").matchAll(/(\d+) (?:failed|skipped|undefined|pending|ambiguous)/g)) notpass += Number(r[1]);
  const suspect = n === undefined || n === 0 || notpass > 0;
  const all = [...status.values()];
  const allpassed = all.length > 0 && all.every((v) => v === "passed");
  row("never-reported-passed", suspect && allpassed, suspect && allpassed ? `the test output shows ${!n ? "no scenarios" : `${notpass} not passed`}, and every example is reported as passed` : "");
}

count();
flush();
