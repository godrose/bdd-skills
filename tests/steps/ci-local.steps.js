const { Given, When, Then } = require("@cucumber/cucumber");
const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const { ROOT } = require("./support");

// A throwaway copy of the local CI script, with fake claude and npm and a fake test run, each logging what ran.
function copy(world, { claude = true, failPlugin = false, failTests = false } = {}) {
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), "cilocal-"));
  const bin = path.join(world.dir, "bin");
  fs.mkdirSync(bin);
  fs.mkdirSync(path.join(world.dir, "tests"));
  fs.copyFileSync(path.join(ROOT, "tests/ci_local.sh"), path.join(world.dir, "tests/ci_local.sh"));
  const log = path.join(world.dir, "ran.log");
  const script = (name, body) => fs.writeFileSync(path.join(bin, name), `#!/bin/sh\n${body}\n`, { mode: 0o755 });
  if (claude) script("claude", `echo "claude $*" >> '${log}'\n${failPlugin ? 'case "$*" in *strict*) exit 1;; esac' : ""}`);
  script("npm", `echo "npm $*" >> '${log}'`);
  fs.writeFileSync(path.join(world.dir, "tests/run.sh"), `#!/bin/bash\necho "tests/run.sh" >> '${log}'\nexit ${failTests ? 1 : 0}\n`);
  world.bin = bin;
  world.log = log;
}

Given("a copy of the local CI script where every step passes", function () { copy(this); });
Given("a copy of the local CI script where the plugin validation fails", function () { copy(this, { failPlugin: true }); });
Given("a copy of the local CI script where the tests fail", function () { copy(this, { failTests: true }); });
Given("a copy of the local CI script with no claude installed", function () { copy(this, { claude: false }); });

When("the local CI is run", function () {
  // Only the fake tools are on the path, plus the system ones the script needs.
  const r = spawnSync("bash", ["tests/ci_local.sh"], { cwd: this.dir, encoding: "utf8", env: { PATH: `${this.bin}:/usr/bin:/bin` } });
  this.status = r.status;
  this.output = (r.stdout || "") + (r.stderr || "");
});

const ran = (w) => (fs.existsSync(w.log) ? fs.readFileSync(w.log, "utf8").trim().split("\n") : []);

Then("the local CI passes", function () { assert.strictEqual(this.status, 0, this.output); });
Then("the local CI fails", function () { assert.notStrictEqual(this.status, 0, this.output); });
Then("the steps ran in this order:", function (table) {
  const names = table.raw().map((r) => r[0]);
  const marks = { "validate the plugin": "claude plugin validate plugin --strict", "validate the marketplace": "claude plugin validate .", "install the scenario runner": "npm ci", "run the tests": "tests/run.sh" };
  assert.deepStrictEqual(ran(this), names.map((n) => marks[n]), this.output);
});
Then("it names the step {string}", function (step) { assert.ok(this.output.includes(step), this.output); });
Then("the step {string} did not run", function (step) {
  const mark = { "run the tests": "tests/run.sh" }[step];
  assert.ok(!ran(this).includes(mark), "ran: " + ran(this).join(", "));
});
Then("it says that claude is not installed", function () { assert.ok(/claude is not installed/i.test(this.output), this.output); });
