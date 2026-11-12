import { Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import type { World } from "./support";
import { claude, readClaude } from "./install-support";

const column = (table: DataTable): string[] => table.raw().map((r) => r[0]);

const installedFiles = (world: World): string[] =>
  ["commands", "agents"].flatMap((d) => fs.readdirSync(claude(world, d)).filter((f) => f.endsWith(".md")).map((f) => `${d}/${f}`)).concat("bdd-config.md");

Then("the output mentions {string}", function (this: World, text: string) { assert.ok(this.output.includes(text), this.output); });

Then("the output mentions:", function (this: World, table: DataTable) {
  for (const text of column(table)) assert.ok(this.output.includes(text), `no "${text}" in: ${this.output}`);
});

Then("the output does not mention {string}", function (this: World, text: string) { assert.ok(!this.output.includes(text), this.output); });
Then("an output line ends with {string}", function (this: World, end: string) { assert.ok(this.output.split(/\r?\n/).some((l) => l.endsWith(end)), this.output); });
Then("no output line ends with {string}", function (this: World, end: string) { assert.ok(!this.output.split(/\r?\n/).some((l) => l.endsWith(end)), this.output); });

Then("the project has these files in its .claude folder:", function (this: World, table: DataTable) {
  for (const rel of column(table)) assert.ok(fs.statSync(claude(this, rel), { throwIfNoEntry: false })?.isFile(), `missing ${rel}`);
});

Then("the project has none of these files in its .claude folder:", function (this: World, table: DataTable) {
  for (const rel of column(table)) assert.ok(!fs.existsSync(claude(this, rel)), `unexpected ${rel}`);
});

Then("the project has no .claude folder", function (this: World) { assert.ok(!fs.existsSync(path.join(this.dir, ".claude"))); });

Then("the file {string} can be run", function (this: World, rel: string) {
  assert.ok(((fs.statSync(claude(this, rel)).mode) & 0o111) !== 0, `${rel} is not executable`);
});

Then("the installed file {string} contains {string}", function (this: World, rel: string, text: string) {
  assert.ok(readClaude(this, rel).includes(text), `${rel} lacks: ${text}`);
});

Then("the installed file {string} does not contain {string}", function (this: World, rel: string, text: string) {
  assert.ok(!readClaude(this, rel).includes(text), `${rel} has: ${text}`);
});

Then("the installed file {string} holds only the line {string}", function (this: World, rel: string, line: string) {
  assert.strictEqual(readClaude(this, rel).replace(/\n+$/, ""), line);
});

Then("the installed file {string} is identical to the kept copy", function (this: World, rel: string) {
  assert.strictEqual(fs.readFileSync(claude(this, rel), "utf8"), this.kept);
});

Then("the second line of {string} is the source line for {string}", function (this: World, rel: string, url: string) {
  const second = readClaude(this, rel).split("\n")[1] ?? "";
  assert.strictEqual(second.split("(")[0].replace(/ +$/, ""), `# Source: ${url}`);
});

Then("no installed command, agent or config mentions {string}", function (this: World, text: string) {
  for (const rel of installedFiles(this)) assert.ok(!readClaude(this, rel).includes(text), `${rel} has: ${text}`);
});

Then("no installed command, agent or config has a plugin-style skill name", function (this: World) {
  for (const rel of installedFiles(this)) assert.ok(!/bdd:(discover|design|implement|run|triage|reconcile|deliver|verifier)/.test(readClaude(this, rel)), `${rel} has a plugin-style skill name`);
});

Then("it reads its scripts from the scripts folder at the repo root", function (this: World) {
  assert.ok(this.subject.includes('SCRIPTS_DIR="$SOURCE_DIR/scripts"'));
});
