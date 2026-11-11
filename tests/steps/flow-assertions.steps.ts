import { Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { ROOT, read, type World } from "./support";
import { FLOWS, cacheDir, flow, npmLog, readRun, runDir } from "./flow-support";

const column = (table: DataTable): string[] => table.raw().map((r) => r[0]);

// The rules table of the last play: rule, held or broken, detail.
const rules = (world: World): string => readRun(world, "rules.tsv");
const stateOf = (world: World, rule: string): string => {
  const row = rules(world).split("\n").map((l) => l.split("\t")).find((c) => c[0] === rule);
  return row ? row[1] : "";
};

Then("the rule {string} is held", function (this: World, rule: string) { assert.strictEqual(stateOf(this, rule), "held", rule); });
Then("the rule {string} is broken", function (this: World, rule: string) { assert.strictEqual(stateOf(this, rule), "broken", rule); });
Then("the rule {string} is not counted", function (this: World, rule: string) { assert.strictEqual(stateOf(this, rule), "", rule); });
Then("the detail of the rules mentions {string}", function (this: World, text: string) {
  assert.ok(rules(this).includes(text), `no "${text}" in: ${rules(this)}`);
});

const call = (world: World, n: number): string => fs.readFileSync(path.join(flow(world).scriptDir, `assistant-args-${n}.txt`), "utf8");

Then("call {int} to the assistant contains:", function (this: World, n: number, table: DataTable) {
  for (const text of column(table)) assert.ok(call(this, n).includes(text), `call ${n} lacks "${text}": ${call(this, n)}`);
});
Then("call {int} to the assistant does not contain:", function (this: World, n: number, table: DataTable) {
  for (const text of column(table)) assert.ok(!call(this, n).includes(text), `call ${n} has "${text}": ${call(this, n)}`);
});

Then("the file {string} of the run contains:", function (this: World, name: string, table: DataTable) {
  const text = readRun(this, name);
  for (const item of column(table)) assert.ok(text.includes(item), `${name} lacks "${item}": ${text}`);
});
Then("the report of the harness contains {string}", function (this: World, text: string) {
  const report = fs.readFileSync(path.join(flow(this).outDir, "c-story-1/report.md"), "utf8");
  assert.ok(report.includes(text), report);
});

Then("the runner was installed {int} time(s)", function (this: World, n: number) {
  const installs = fs.readFileSync(npmLog(flow(this)), "utf8").split("\n").filter((l) => l.startsWith("ci")).length;
  assert.strictEqual(installs, n);
});
Then("the cache holds the runner under the first 16 characters of the hash of the lockfile", function (this: World) {
  const lock = fs.readFileSync(path.join(FLOWS, "fixtures/c/project/package-lock.json"));
  const key = crypto.createHash("sha256").update(lock).digest("hex").slice(0, 16);
  assert.ok(fs.statSync(path.join(cacheDir(flow(this)), key, "node_modules/.bin/cucumber-js"), { throwIfNoEntry: false })?.isFile(), `no runner in the cache under ${key}`);
});
Then("the project of the run has the runner", function (this: World) {
  assert.ok(fs.statSync(path.join(runDir(flow(this)), "project/node_modules/.bin/cucumber-js"), { throwIfNoEntry: false })?.isFile());
});
Then("no session was started", function (this: World) {
  assert.ok(!fs.existsSync(path.join(flow(this).scriptDir, "assistant-args-1.txt")), "a session was started without a runner");
});
Then("the cache holds nothing", function (this: World) {
  const dir = cacheDir(flow(this));
  assert.ok(!fs.existsSync(dir) || fs.readdirSync(dir).length === 0, "a failed install left a cache behind");
});

Then("the line for the rule {string} is marked {string}", function (this: World, rule: string, mark: string) {
  assert.ok(linesOf(this, rule).some((l) => l.includes(mark)), this.output);
});
Then("the line for the rule {string} is not marked {string}", function (this: World, rule: string, mark: string) {
  assert.ok(!linesOf(this, rule).some((l) => l.includes(mark)), this.output);
});
const linesOf = (world: World, rule: string): string[] => world.output.split("\n").filter((l) => l.toLowerCase().includes(rule.toLowerCase()));

Then("the output does not mention:", function (this: World, table: DataTable) {
  for (const text of column(table)) assert.ok(!this.output.includes(text), `has "${text}" in: ${this.output}`);
});

Then("these files exist:", function (this: World, table: DataTable) {
  for (const rel of column(table)) assert.ok(fs.statSync(path.join(ROOT, rel), { throwIfNoEntry: false })?.isFile(), `missing file ${rel}`);
});
Then("the file {string} does not exist", function (this: World, rel: string) {
  assert.ok(!fs.existsSync(path.join(ROOT, rel)), `${rel} exists`);
});
Then("they hold {int} scenario(s)", function (this: World, n: number) { assert.strictEqual(flow(this).scenarioCount, n); });

Then("none of them contains {string}", function (this: World, text: string) {
  for (const rel of this.files) assert.ok(!read(rel).includes(text), `${rel} has: ${text}`);
});
