import { Given, When, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { ROOT, type World } from "./support";

// A throwaway copy of the test run: the real tests/run.sh, a fake scenario runner and fake bash test files.
function newCopy(world: World): void {
  world.dir = fs.mkdtempSync(path.join(os.tmpdir(), "testrun-"));
  fs.mkdirSync(path.join(world.dir, "tests"));
  fs.copyFileSync(path.join(ROOT, "tests/run.sh"), path.join(world.dir, "tests/run.sh"));
}
function fakeRunner(world: World, output: string, code: number): void {
  const bin = path.join(world.dir, "node_modules/.bin");
  fs.mkdirSync(bin, { recursive: true });
  fs.writeFileSync(path.join(bin, "cucumber-js"), `#!/bin/sh\nprintf '%s\\n' '${output}'\nexit ${code}\n`, { mode: 0o755 });
}

Given("a copy of the test run with no scenario runner installed", function (this: World) { newCopy(this); });
Given("a copy of the test run whose scenario runner finds no scenario", function (this: World) { newCopy(this); fakeRunner(this, "0 scenarios", 0); });
Given("a copy of the test run whose scenarios pass", function (this: World) { newCopy(this); fakeRunner(this, "3 scenarios (3 passed)", 0); });
Given("a copy of the test run whose scenarios fail", function (this: World) { newCopy(this); fakeRunner(this, "3 scenarios (1 failed, 2 passed)", 1); });

Given("a bash test file that passes", function (this: World) {
  fs.writeFileSync(path.join(this.dir, "tests/test_ok.sh"), "#!/bin/bash\necho bash-file-ran >> \"$(dirname \"$0\")/../ran.txt\"\nexit 0\n");
});
Given("a bash test file that fails", function (this: World) {
  fs.writeFileSync(path.join(this.dir, "tests/test_bad.sh"), "#!/bin/bash\necho bash-file-ran >> \"$(dirname \"$0\")/../ran.txt\"\nexit 1\n");
});

When("the tests are run", function (this: World) {
  const r = spawnSync("bash", ["tests/run.sh"], { cwd: this.dir, encoding: "utf8" });
  this.status = r.status;
  this.output = (r.stdout || "") + (r.stderr || "");
});

Then("the run fails", function (this: World) { assert.notStrictEqual(this.status, 0, this.output); });
Then("the run passes", function (this: World) { assert.strictEqual(this.status, 0, this.output); });
Then("it tells the contributor to run {string}", function (this: World, cmd: string) { assert.ok(this.output.includes(cmd), this.output); });
Then("it says that no scenario ran", function (this: World) { assert.ok(/no scenario ran/i.test(this.output), this.output); });
Then("the bash test file still ran after the scenarios", function (this: World) {
  assert.ok(fs.existsSync(path.join(this.dir, "ran.txt")), "the bash file did not run");
});
