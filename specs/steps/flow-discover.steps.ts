// Steps for the discover flow harness. They share the support of the deliver harness, set to discover and fixture a.
import { Given, Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { ROOT, type World } from "./support";
import { FLOWS, baseDir, flow, readReport, readRun, runDir } from "./flow-support";

const OPENING = `What exists: one scenario covers part of it.
Is that right?`;
const UNFINISHED_READINESS = `## Readiness
Not ready. Still needed:
- Your answer to the open question.`;

const column = (table: DataTable): string[] => table.raw().map((r) => r[0]);

Given("the harness runs discover on fixture {string}", function (this: World, fixture: string) {
  const f = flow(this);
  f.command = "discover";
  f.fixture = fixture;
  f.story = "";
});

Given("the assistant opens with what exists and one question", function (this: World) { flow(this).messages.push(OPENING); });
Given("the assistant ends with an unfinished readiness block", function (this: World) { flow(this).messages.push(UNFINISHED_READINESS); });
Given("the assistant says:", function (this: World, text: string) { flow(this).messages.push(text); });
Given("the assistant gives no answer", function (this: World) { flow(this).messages = []; });
Given("the harness is limited to {int} turns", function (this: World, turns: number) { flow(this).turns = turns; });
Given("the output folder is given as a relative path", function (this: World) { flow(this).relativeOut = true; });
Given("no claude is on the path", function (this: World) { flow(this).noClaude = true; });

// A copy of the harness outside the repo, whose text fixtures end their lines with CRLF, as a clone with autocrlf does.
Given("the fixture text files of a copy of the harness have Windows line endings", function (this: World) {
  const f = flow(this);
  const copy = path.join(f.tmp, "crlf/flows");
  fs.cpSync(FLOWS, copy, { recursive: true, filter: (src) => !src.startsWith(path.join(FLOWS, "results")) });
  for (const name of fs.readdirSync(path.join(copy, "fixtures"))) {
    for (const file of ["persona.txt", "story.txt"]) {
      const p = path.join(copy, "fixtures", name, file);
      if (fs.existsSync(p)) fs.writeFileSync(p, fs.readFileSync(p, "utf8").replace(/\r?\n/g, "\r\n"));
    }
  }
  f.harness = path.join(copy, "run.sh");
});

const files = (dir: string): string[] =>
  fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? files(path.join(dir, e.name)) : [path.join(dir, e.name)]));
const fixtureFiles = (fixture: string, ...extensions: string[]): string[] =>
  files(path.join(FLOWS, "fixtures", fixture)).filter((p) => extensions.some((x) => p.endsWith(x)));

Given("the feature files of fixture {string}", function (this: World, fixture: string) {
  const lines = fixtureFiles(fixture, ".feature").flatMap((p) => fs.readFileSync(p, "utf8").split("\n"));
  flow(this).scenarioCount = lines.filter((l) => /^ *Scenario/.test(l)).length;
});

Then("the file {string} of the run reads {string}", function (this: World, name: string, text: string) {
  assert.strictEqual(readRun(this, name).trim(), text);
});
Then("the run folder has:", function (this: World, table: DataTable) {
  for (const name of column(table)) assert.ok(fs.existsSync(path.join(runDir(flow(this)), name)), `no ${name} in the run folder`);
});
Then("the first prompt to the product manager model contains the first line of the persona card of the fixture", function (this: World) {
  const f = flow(this);
  const persona = fs.readFileSync(path.join(FLOWS, "fixtures", f.fixture, "persona.txt"), "utf8").trim();
  const firstLine = fs.readFileSync(path.join(FLOWS, "personas", `${persona}.md`), "utf8").replace(/\r/g, "").split("\n")[0];
  const prompt = fs.readFileSync(path.join(f.scriptDir, "pm-prompt-1.txt"), "utf8");
  assert.ok(firstLine.length > 0 && prompt.includes(firstLine), `no "${firstLine}" in: ${prompt}`);
});
Then("the report of the harness contains:", function (this: World, table: DataTable) {
  const report = readReport(this);
  for (const text of column(table)) assert.ok(report.includes(text), `no "${text}" in: ${report}`);
});
Then("the report of the harness does not contain {string}", function (this: World, text: string) {
  assert.ok(!readReport(this).includes(text), `has "${text}"`);
});
Then("the report of the harness does not contain:", function (this: World, table: DataTable) {
  const report = readReport(this);
  for (const text of column(table)) assert.ok(!report.includes(text), `has "${text}" in: ${report}`);
});
Then("no output folder was written", function (this: World) {
  assert.ok(!fs.existsSync(flow(this).outDir), `${baseDir(flow(this))} exists`);
});

Then("fixture {string} holds {int} feature file(s)", function (this: World, fixture: string, n: number) {
  assert.strictEqual(fixtureFiles(fixture, ".feature").length, n);
});
Then("fixture {string} holds no feature files and no screens", function (this: World, fixture: string) {
  assert.deepStrictEqual(fixtureFiles(fixture, ".feature", ".html", ".tsx", ".vue").map((p) => path.relative(ROOT, p)), []);
});
