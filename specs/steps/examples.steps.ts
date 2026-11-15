// Step definitions for the examples guard (scripts/examples.sh).
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Given, Then, When } from "@cucumber/cucumber";
import { newProject } from "./decisions-support";
import { ROOT, type World } from "./support";

const SCRIPT = path.join(ROOT, "scripts/examples.sh");

const EXAMPLES = `# Late loans

Rule: A late loan shows how late it is and the fee.

E1. A loan due on 1 Nov and returned on 1 Nov shows no late label and a fee of 0.
E2. A loan due on 1 Nov and returned on 4 Nov shows "late by 3 days" and a fee of 5.
`;

const FEATURE = `Feature: Late loans

  @spec-on-time @example-E1 @src-? @gen-?
  Scenario: A loan returned on time shows no late label
    Given a loan due on "1 Nov"
    When it is returned on "1 Nov"
    Then the loan shows no late label and a fee of 0

  @spec-late-label @example-E2 @src-? @gen-?
  Scenario: A loan returned 3 days late shows the label and the fee
    Given a loan due on "1 Nov"
    When it is returned on "4 Nov"
    Then the loan shows "late by 3 days" and a fee of 5
`;

function runScript(world: World, args: string[]): { status: number; output: string } {
  const r = spawnSync("/bin/bash", ["-c", 'exec /bin/bash "$0" "$@" 2>&1', SCRIPT, ...args], { cwd: world.dir, encoding: "utf8" });
  return { status: r.status ?? -1, output: r.stdout.replace(/\n+$/, "") };
}

function run(world: World, args: string[]): void {
  const r = runScript(world, args);
  world.status = r.status;
  world.output = r.output;
}

const file = (world: World, rel: string): string => path.join(world.dir, "features", rel);

function write(world: World, rel: string, text: string): void {
  if (!world.dir) newProject(world);
  fs.mkdirSync(path.dirname(file(world, rel)), { recursive: true });
  fs.writeFileSync(file(world, rel), text);
}

// Fills @src-? and @gen-? on the tag line of each generated scenario, with the hashes the script gives.
function stamp(world: World, rel: string): void {
  const feature = file(world, rel);
  const examples = feature.replace(/\.feature$/, ".examples.md");
  const lines = fs.readFileSync(feature, "utf8").split("\n");
  const out = lines.map((line) => {
    const m = line.match(/@example-(E\d+)/);
    if (!m) return line;
    const src = runScript(world, ["source-hash", examples, m[1]]);
    const gen = runScript(world, ["scenario-hash", feature, m[1]]);
    assert.strictEqual(src.status, 0, `source-hash: ${src.output}`);
    assert.strictEqual(gen.status, 0, `scenario-hash: ${gen.output}`);
    return line.replace(/@src-(\?|[0-9a-f]{8})/, `@src-${src.output}`).replace(/@gen-(\?|[0-9a-f]{8})/, `@gen-${gen.output}`);
  });
  fs.writeFileSync(feature, out.join("\n"));
}

function lateLoans(world: World, folder: string, crlf: boolean): void {
  newProject(world);
  const eol = (t: string): string => (crlf ? t.replace(/\n/g, "\r\n") : t);
  const base = folder ? `${folder}/` : "";
  write(world, `${base}loans.examples.md`, eol(EXAMPLES));
  write(world, `${base}loans.feature`, eol(FEATURE));
  stamp(world, `${base}loans.feature`);
}

Given("a project with the late loan feature and no examples file", function (this: World) {
  newProject(this);
  write(this, "loans.feature", FEATURE.replace(/ @example-E\d+ @src-\? @gen-\?/g, ""));
});
Given("a project with the late loan examples and their scenarios", function (this: World) { lateLoans(this, "", false); });
Given("a project with the late loan examples and their scenarios in the folder {string}", function (this: World, folder: string) { lateLoans(this, folder, false); });
Given("a project with the late loan examples and their scenarios, with Windows line endings", function (this: World) { lateLoans(this, "", true); });
Given("the examples file {string} reads:", function (this: World, rel: string, text: string) { write(this, rel, text + "\n"); });
Given("the examples file {string} gets the line {string}", function (this: World, rel: string, line: string) {
  fs.appendFileSync(file(this, rel), line + "\n");
});
Given("the text {string} is replaced by {string} in the examples file {string}", function (this: World, from: string, to: string, rel: string) {
  const text = fs.readFileSync(file(this, rel), "utf8");
  assert.ok(text.includes(from), `no "${from}" in ${rel}`);
  fs.writeFileSync(file(this, rel), text.split(from).join(to));
});
Given("the feature file {string} gets a scenario owned by Gherkin", function (this: World, rel: string) {
  fs.appendFileSync(file(this, rel), `\n  @spec-technical\n  Scenario: The export job is queued\n    Given a queue\n    Then the job is queued\n`);
});
Given("the source hash of {string} in the examples file {string} is remembered", function (this: World, id: string, rel: string) {
  this.kept = runScript(this, ["source-hash", file(this, rel), id]).output;
});
Given("the scenario hash of {string} in the feature file {string} is remembered", function (this: World, id: string, rel: string) {
  this.kept = runScript(this, ["scenario-hash", file(this, rel), id]).output;
});
Given("the examples file {string} is rewritten with Windows line endings", function (this: World, rel: string) {
  fs.writeFileSync(file(this, rel), fs.readFileSync(file(this, rel), "utf8").replace(/\r\n/g, "\n").replace(/\n/g, "\r\n"));
});
Given("the feature file {string} is rewritten with Windows line endings", function (this: World, rel: string) {
  fs.writeFileSync(file(this, rel), fs.readFileSync(file(this, rel), "utf8").replace(/\r\n/g, "\n").replace(/\n/g, "\r\n"));
});
Given("the feature file {string} is stamped", function (this: World, rel: string) { stamp(this, rel); });

When("the examples are checked", function (this: World) { run(this, ["check", "--features", "features"]); });
When("the examples are checked in the folder {string}", function (this: World, folder: string) { run(this, ["check", "--features", folder]); });
When("the source hash of {string} is asked for in the examples file {string}", function (this: World, id: string, rel: string) {
  run(this, ["source-hash", file(this, rel), id]);
});
When("the scenario hash of {string} is asked for in the feature file {string}", function (this: World, id: string, rel: string) {
  run(this, ["scenario-hash", file(this, rel), id]);
});

Then("the output is the remembered hash", function (this: World) { assert.strictEqual(this.output, this.kept); });

const sha8 = (text: string): string => crypto.createHash("sha256").update(text).digest("hex").slice(0, 8);
Then("the output is the first 8 characters of the SHA-256 of {string}", function (this: World, text: string) { assert.strictEqual(this.output, sha8(text)); });
Then("the output is the first 8 characters of the SHA-256 of the lines {string}, {string} and {string}", function (this: World, a: string, b: string, c: string) {
  assert.strictEqual(this.output, sha8(`${a}\n${b}\n${c}\n`));
});
