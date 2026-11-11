import { Then, When } from "@cucumber/cucumber";
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
`;

When("the eval runner is run with a stand-in for the eval tool", function (this: World) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "runsh-"));
  fs.mkdirSync(path.join(tmp, "bin"));
  fs.writeFileSync(path.join(tmp, "bin/claude"), STAND_IN, { mode: 0o755 });
  const r = spawnSync("bash", ["evals/run.sh", "--runs", "1"], {
    cwd: ROOT,
    encoding: "utf8",
    env: { ...process.env, RUNSH_OUT: tmp, PATH: `${path.join(tmp, "bin")}:${process.env.PATH}` },
  });
  const seen = (name: string): string => (fs.existsSync(path.join(tmp, name)) ? fs.readFileSync(path.join(tmp, name), "utf8") : "");
  this.status = r.status;
  this.output = seen("evals.txt");
  this.subject = seen("plugin.txt");
  fs.rmSync(tmp, { recursive: true, force: true });
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
