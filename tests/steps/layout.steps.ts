import { Given, Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { ROOT, read, type World } from "./support";

const abs = (rel: string): string => path.join(ROOT, rel);
const items = (table: DataTable): string[] => table.raw().flat();
const missing = (rel: string, check: (s: fs.Stats) => boolean): boolean => {
  try { return !check(fs.statSync(abs(rel))); } catch { return true; }
};

Given("the repository", function (this: World) { /* informational: the scenarios read the repo as it is */ });

Then("the repo has these files:", function (this: World, table: DataTable) {
  const bad = items(table).filter((p) => missing(p, (s) => s.isFile()));
  assert.deepStrictEqual(bad, [], "missing files: " + bad.join(", "));
});
Then("the repo has these folders:", function (this: World, table: DataTable) {
  const bad = items(table).filter((p) => missing(p, (s) => s.isDirectory()));
  assert.deepStrictEqual(bad, [], "missing folders: " + bad.join(", "));
});
Then("the repo has these paths:", function (this: World, table: DataTable) {
  const bad = items(table).filter((p) => !fs.existsSync(abs(p)));
  assert.deepStrictEqual(bad, [], "missing at the repo root: " + bad.join(", "));
});
Then("the repo has none of these paths:", function (this: World, table: DataTable) {
  const bad = items(table).filter((p) => fs.existsSync(abs(p)));
  assert.deepStrictEqual(bad, [], "still there: " + bad.join(", "));
});

Given("the marketplace file", function (this: World) { this.subject = read(".claude-plugin/marketplace.json"); });
Then("its first plugin has the source {string}", function (this: World, source: string) {
  assert.strictEqual(JSON.parse(this.subject).plugins?.[0]?.source, source);
});

Given("the file {string}", function (this: World, rel: string) { this.subject = read(rel); });
Given("the listing README", function (this: World) { this.subject = read("plugin/README.md"); });
Then("it has at least {int} words outside code blocks", function (this: World, min: number) {
  let inCode = false;
  let words = 0;
  for (const line of this.subject.split("\n")) {
    if (line.startsWith("```")) { inCode = !inCode; continue; }
    if (!inCode) words += line.split(/\s+/).filter(Boolean).length;
  }
  assert.ok(words >= min, `${words} words outside code, need ${min}`);
});
Then("it contains {string}", function (this: World, text: string) { assert.ok(this.subject.includes(text), `lacks: ${text}`); });
Then("it contains:", function (this: World, table: DataTable) {
  const bad = items(table).filter((t) => !this.subject.includes(t));
  assert.deepStrictEqual(bad, [], "lacks: " + bad.join(", "));
});
Then("it does not contain {string}", function (this: World, text: string) { assert.ok(!this.subject.includes(text), `has: ${text}`); });

Given("the listing icon", function (this: World) {
  this.subject = "plugin/.claude-plugin/icon.png";
  assert.ok(!missing(this.subject, (s) => s.isFile()), "missing file " + this.subject);
});
const icon = (w: World): Buffer => fs.readFileSync(abs(w.subject));
Then("it is a PNG", function (this: World) {
  assert.deepStrictEqual([...icon(this).subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
});
Then("it is square", function (this: World) {
  const b = icon(this);
  assert.strictEqual(b.readUInt32BE(16), b.readUInt32BE(20));
});
Then("it is between {int} and {int} pixels on each side", function (this: World, min: number, max: number) {
  const w = icon(this).readUInt32BE(16);
  assert.ok(w >= min && w <= max, `${w}px, need ${min} to ${max}`);
});
Then("it is under 2 MB", function (this: World) { assert.ok(icon(this).length < 2097152, "2 MB or more"); });

Given("the plugin licence copy", function (this: World) {
  this.subject = "plugin/LICENSE";
  assert.ok(!missing(this.subject, (s) => s.isFile()), "plugin/LICENSE is missing");
});
Then("it is identical to the root licence", function (this: World) {
  assert.ok(fs.readFileSync(abs("LICENSE")).equals(fs.readFileSync(abs(this.subject))), "plugin/LICENSE differs from LICENSE");
});

Then("it reads the plugin from the plugin folder of its source", function (this: World) {
  assert.ok(this.subject.includes('PLUGIN_DIR="$SOURCE_DIR/plugin"'), 'lacks: PLUGIN_DIR="$SOURCE_DIR/plugin"');
});
Then("it says {string} when the plugin folder is missing", function (this: World, message: string) {
  assert.ok(this.subject.includes(message), `lacks: ${message}`);
});

const walk = (dir: string): string[] =>
  fs.readdirSync(abs(dir), { withFileTypes: true }).flatMap((e) => {
    const rel = path.join(dir, e.name);
    if (e.isDirectory()) return e.name === "results" ? [] : walk(rel);
    return [rel];
  });
Given("the plugin folder", function (this: World) { this.files = walk("plugin"); });
Then("no file in it names any of:", function (this: World, table: DataTable) {
  const words = items(table);
  const bad = this.files.filter((f) => {
    const b = fs.readFileSync(abs(f));
    return !b.includes(0) && words.some((w) => b.toString("utf8").includes(w));
  });
  assert.deepStrictEqual(bad, [], "names the CI token setup: " + bad.join(", "));
});

Given("the files tracked in the plugin folder", function (this: World) {
  this.files = execFileSync("git", ["-C", ROOT, "ls-files", "plugin"], { encoding: "utf8" }).split("\n").filter(Boolean);
});
Then("every one is Markdown, text, JSON, YAML, PNG, JPEG, GIF, WebP or ICO, or is a LICENSE or .gitignore file", function (this: World) {
  const bad = this.files.filter((f) => !/\.(md|txt|json|yaml|yml|png|jpe?g|gif|webp|ico)$/.test(f) && !/(^|\/)(LICENSE|\.gitignore)$/.test(f));
  assert.deepStrictEqual(bad, [], "a type the directory refuses: " + bad.join(", "));
});
Then("none of them starts with {string}", function (this: World, start: string) {
  const bad = this.files.filter((f) => fs.readFileSync(abs(f)).subarray(0, start.length).toString("latin1") === start);
  assert.deepStrictEqual(bad, [], `starts with ${start}: ` + bad.join(", "));
});
Then("none of them is a package-manager file", function (this: World) {
  const bad = this.files.filter((f) => /(^|\/)(package(-lock)?\.json|pnpm-workspace\.yaml|\.npmrc|yarn\.lock)$/.test(f));
  assert.deepStrictEqual(bad, [], "package-manager files: " + bad.join(", "));
});

Given("the commands and agents of the plugin", function (this: World) {
  const list = (dir: string): string[] => fs.existsSync(abs(dir)) ? fs.readdirSync(abs(dir)).filter((f) => f.endsWith(".md")).map((f) => path.join(dir, f)) : [];
  this.files = [...list("plugin/commands"), ...list("plugin/agents")];
});
Then("none of them pre-approves a tool beyond Read, Grep, Glob and LS", function (this: World) {
  const bad = this.files.flatMap((f) => {
    const line = read(f).split("\n").find((l) => /^(allowed-tools|allowedTools|tools):/.test(l)) ?? "";
    const extra = (line.match(/"[^"]*"/g) ?? []).map((q) => q.slice(1, -1)).filter((t) => !/^(Read|Grep|Glob|LS)$/.test(t));
    return extra.length ? [`${path.basename(f)}: ${extra.join(" ")}`] : [];
  });
  assert.deepStrictEqual(bad, [], "pre-approves tools beyond the read tools: " + bad.join("; "));
});
