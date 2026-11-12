import { After, Given, Then, When } from "@cucumber/cucumber";
import assert from "node:assert";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { ROOT, type World } from "./support";

const lines = (w: World): string[] => w.subject.split("\n");

Then("it has at least {int} graders", function (this: World, min: number) {
  const n = lines(this).filter((l) => l.startsWith("  - type:")).length;
  assert.ok(n >= min, `${n} graders, expected at least ${min}`);
});

Then("it has {int} judge graders", function (this: World, want: number) {
  const n = lines(this).filter((l) => l.includes("type: llm")).length;
  assert.strictEqual(n, want, `${n} judge graders, expected ${want}`);
});

Then("none of its judge graders has a compound name", function (this: World) {
  const all = lines(this);
  const bad = all.filter((l, i) => all[i - 1]?.includes("type: llm") && l.includes("-and-"));
  assert.deepStrictEqual(bad, [], "compound names: " + bad.join(" | "));
});

Then("it has {int} lines containing {string}", function (this: World, want: number, text: string) {
  const n = lines(this).filter((l) => l.includes(text)).length;
  assert.strictEqual(n, want, `${n} lines contain ${text}, expected ${want}`);
});

Then("it does not set {string} above the step level", function (this: World, name: string) {
  const bad = lines(this).filter((l) => new RegExp(`^ {0,8}${name}`).test(l));
  assert.deepStrictEqual(bad, [], "set above the step level: " + bad.join(" | "));
});

const STAND_IN = `#!/bin/bash
echo "ARGS: $*" > "$RUNSH_OUT/args.txt"
ls "$3/evals" > "$RUNSH_OUT/evals.txt"
ls "$3" > "$RUNSH_OUT/plugin.txt"
if [ -n "$RUNSH_MARK" ]; then mkdir -p "$3/evals/results/$RUNSH_MARK"; echo kept > "$3/evals/results/$RUNSH_MARK/result.txt"; fi
exit "\${RUNSH_EXIT:-0}"
`;

const MARK = `standin-${process.pid}`;
const resultsOf = (): string => path.join(ROOT, "evals/results", MARK);

function runWithStandIn(world: World, env: NodeJS.ProcessEnv): void {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "runsh-"));
  fs.mkdirSync(path.join(tmp, "bin"));
  fs.writeFileSync(path.join(tmp, "bin/claude"), STAND_IN, { mode: 0o755 });
  const r = spawnSync("bash", ["evals/run.sh", "--runs", "1"], {
    cwd: ROOT,
    encoding: "utf8",
    env: { ...process.env, ...env, RUNSH_OUT: tmp, PATH: `${path.join(tmp, "bin")}:${process.env.PATH}` },
  });
  const seen = (name: string): string => (fs.existsSync(path.join(tmp, name)) ? fs.readFileSync(path.join(tmp, name), "utf8") : "");
  world.status = r.status;
  world.output = seen("evals.txt");
  world.subject = seen("plugin.txt");
  world.kept = seen("args.txt");
  fs.rmSync(tmp, { recursive: true, force: true });
}

After(function () { fs.rmSync(resultsOf(), { recursive: true, force: true }); });

When("the eval runner is run with a stand-in for the eval tool", function (this: World) { runWithStandIn(this, {}); });
When("the eval runner is run with a stand-in that fails with status {int}", function (this: World, status: number) {
  runWithStandIn(this, { RUNSH_EXIT: String(status), RUNSH_MARK: MARK });
});
When("the eval runner is run with a stand-in that leaves a result folder", function (this: World) {
  runWithStandIn(this, { RUNSH_MARK: MARK });
});

Then("the stand-in was called with {string}", function (this: World, text: string) {
  assert.ok(this.kept.includes(text), `the eval tool got: ${this.kept}`);
});
Then("the result folder of the stand-in is in the evals results of the repo", function (this: World) {
  assert.ok(fs.existsSync(path.join(resultsOf(), "result.txt")), "the results were not copied back");
});

Then("the stand-in saw {string} in the evals folder of the plugin copy", function (this: World, name: string) {
  assert.ok(this.output.split("\n").includes(name), `not placed under the plugin copy: ${this.output.replace(/\n/g, " ")}`);
});

Then("the stand-in saw no case file directly in the evals folder of the plugin copy", function (this: World) {
  assert.ok(!this.output.split("\n").includes("case.yaml"), "run.sh copied a case's files into evals/ directly");
});

Then("the stand-in saw {string} in the plugin copy", function (this: World, name: string) {
  assert.ok(this.subject.split("\n").includes(name), `the plugin was not copied: ${this.subject.replace(/\n/g, " ")}`);
});

// The lint script of the design-lint-draft fixture, run on a project that holds only the feature files a scenario names.
const LINT = path.join(ROOT, "evals/design-lint-draft/fixture/fake-lint.sh");

Given("a project with the lint script of the lint fixture and no feature files", function (this: World) {
  this.dir = fs.mkdtempSync(path.join(os.tmpdir(), "lint-"));
  fs.mkdirSync(path.join(this.dir, "features"));
  fs.copyFileSync(LINT, path.join(this.dir, "fake-lint.sh"));
});
Given("a project with the lint script and the feature files of the lint fixture", function (this: World) {
  this.dir = fs.mkdtempSync(path.join(os.tmpdir(), "lint-"));
  fs.cpSync(path.join(ROOT, "evals/design-lint-draft/fixture/features"), path.join(this.dir, "features"), { recursive: true });
  fs.copyFileSync(LINT, path.join(this.dir, "fake-lint.sh"));
});
Given("the lint project has the feature file {string} that reads:", function (this: World, rel: string, text: string) {
  fs.writeFileSync(path.join(this.dir, "features", rel), text + "\n");
});
When("the lint script is run", function (this: World) {
  const r = spawnSync("sh", ["fake-lint.sh"], { cwd: this.dir, encoding: "utf8" });
  this.status = r.status;
  this.output = (r.stdout ?? "") + (r.stderr ?? "");
  fs.rmSync(this.dir, { recursive: true, force: true });
});
