import { Given, When, Then, type DataTable } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";

type Options = { claude?: boolean; failPlugin?: boolean; failTypes?: boolean; failTests?: boolean };

// A throwaway copy of the local CI script, with fake claude, npm and npx and a fake test run, each logging what ran.
function copy(world: World, { claude = true, failPlugin = false, failTypes = false, failTests = false }: Options = {}): void {
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), "cilocal-"));
  const bin = path.join(world.dir, "bin");
  fs.mkdirSync(bin);
  fs.mkdirSync(path.join(world.dir, "tests"));
  fs.copyFileSync(path.join(ROOT, "tests/ci_local.sh"), path.join(world.dir, "tests/ci_local.sh"));
  const log = path.join(world.dir, "ran.log");
  const script = (name: string, body: string) => fs.writeFileSync(path.join(bin, name), `#!/bin/sh\n${body}\n`, { mode: 0o755 });
  if (claude) script("claude", `echo "claude $*" >> '${log}'\n${failPlugin ? 'case "$*" in *strict*) exit 1;; esac' : ""}`);
  script("npm", `echo "npm $*" >> '${log}'`);
  script("npx", `echo "npx $*" >> '${log}'\n${failTypes ? "exit 1" : ""}`);
  fs.writeFileSync(path.join(world.dir, "tests/run.sh"), `#!/bin/bash\necho "tests/run.sh" >> '${log}'\nexit ${failTests ? 1 : 0}\n`);
  world.bin = bin;
  world.log = log;
}

Given("a copy of the local CI script where every step passes", function (this: World) { copy(this); });
Given("a copy of the local CI script where the plugin validation fails", function (this: World) { copy(this, { failPlugin: true }); });
Given("a copy of the local CI script where the type check fails", function (this: World) { copy(this, { failTypes: true }); });
Given("a copy of the local CI script where the tests fail", function (this: World) { copy(this, { failTests: true }); });
Given("a copy of the local CI script with no claude installed", function (this: World) { copy(this, { claude: false }); });

When("the local CI is run", function (this: World) {
  // Only the fake tools are on the path, plus the system ones the script needs.
  const r = spawnSync("bash", ["tests/ci_local.sh"], { cwd: this.dir, encoding: "utf8", env: { PATH: `${this.bin}:/usr/bin:/bin` } });
  this.status = r.status;
  this.output = (r.stdout || "") + (r.stderr || "");
});

const ran = (w: World): string[] => (fs.existsSync(w.log) ? fs.readFileSync(w.log, "utf8").trim().split("\n") : []);

const MARKS: Record<string, string> = {
  "validate the plugin": "claude plugin validate plugin --strict",
  "validate the marketplace": "claude plugin validate .",
  "install the scenario runner": "npm ci",
  "type-check the steps": "npx tsc --noEmit --noUnusedLocals --noUnusedParameters",
  "run the tests": "tests/run.sh",
};

Then("the local CI passes", function (this: World) { assert.strictEqual(this.status, 0, this.output); });
Then("the local CI fails", function (this: World) { assert.notStrictEqual(this.status, 0, this.output); });
Then("the steps ran in this order:", function (this: World, table: DataTable) {
  const names = table.raw().map((r) => r[0]);
  assert.deepStrictEqual(ran(this), names.map((n) => MARKS[n]), this.output);
});
Then("it names the step {string}", function (this: World, step: string) { assert.ok(this.output.includes(step), this.output); });
Then("the step {string} did not run", function (this: World, step: string) {
  assert.ok(!ran(this).includes(MARKS[step]), "ran: " + ran(this).join(", "));
});
Then("it says that claude is not installed", function (this: World) { assert.ok(/claude is not installed/i.test(this.output), this.output); });
