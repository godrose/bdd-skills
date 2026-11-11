const { Given, When, Then } = require("@cucumber/cucumber");
const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");
const { ROOT } = require("./support");

// A throwaway copy of the test run: the real tests/run.sh, a fake scenario runner and fake bash test files.
function newCopy(world) {
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), "testrun-"));
  fs.mkdirSync(path.join(world.dir, "tests"));
  fs.copyFileSync(path.join(ROOT, "tests/run.sh"), path.join(world.dir, "tests/run.sh"));
}
function fakeRunner(world, output, code) {
  const bin = path.join(world.dir, "node_modules/.bin");
  fs.mkdirSync(bin, { recursive: true });
  fs.writeFileSync(path.join(bin, "cucumber-js"), `#!/bin/sh\nprintf '%s\\n' '${output}'\nexit ${code}\n`, { mode: 0o755 });
}

Given("a copy of the test run with no scenario runner installed", function () { newCopy(this); });
Given("a copy of the test run whose scenario runner finds no scenario", function () { newCopy(this); fakeRunner(this, "0 scenarios", 0); });
Given("a copy of the test run whose scenarios pass", function () { newCopy(this); fakeRunner(this, "3 scenarios (3 passed)", 0); });
Given("a copy of the test run whose scenarios fail", function () { newCopy(this); fakeRunner(this, "3 scenarios (1 failed, 2 passed)", 1); });

Given("a bash test file that passes", function () {
  fs.writeFileSync(path.join(this.dir, "tests/test_ok.sh"), "#!/bin/bash\necho bash-file-ran >> \"$(dirname \"$0\")/../ran.txt\"\nexit 0\n");
});
Given("a bash test file that fails", function () {
  fs.writeFileSync(path.join(this.dir, "tests/test_bad.sh"), "#!/bin/bash\necho bash-file-ran >> \"$(dirname \"$0\")/../ran.txt\"\nexit 1\n");
});

When("the tests are run", function () {
  const r = spawnSync("bash", ["tests/run.sh"], { cwd: this.dir, encoding: "utf8" });
  this.status = r.status;
  this.output = (r.stdout || "") + (r.stderr || "");
});

Then("the run fails", function () { assert.notStrictEqual(this.status, 0, this.output); });
Then("the run passes", function () { assert.strictEqual(this.status, 0, this.output); });
Then("it tells the contributor to run {string}", function (cmd) { assert.ok(this.output.includes(cmd), this.output); });
Then("it says that no scenario ran", function () { assert.ok(/no scenario ran/i.test(this.output), this.output); });
Then("the bash test file still ran after the scenarios", function () {
  assert.ok(fs.existsSync(path.join(this.dir, "ran.txt")), "the bash file did not run");
});
