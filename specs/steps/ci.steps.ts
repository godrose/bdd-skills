import { Given, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import { read, type World } from "./support";

const at = (text: string, needle: string): number => {
  const i = text.indexOf(needle);
  assert.ok(i >= 0, "the CI workflow lacks: " + needle);
  return i;
};

Given("the CI workflow", function (this: World) { this.ci = read(".github/workflows/ci.yml"); this.subject = this.ci; });
Then("it installs the scenario runner before it runs the tests", function (this: World) {
  assert.ok(at(this.ci, "npm ci") < at(this.ci, "bash tests/run.sh"));
});
Then("it type-checks the steps before it runs the tests", function (this: World) {
  assert.ok(at(this.ci, "npm ci") < at(this.ci, "tsc --noEmit"), "the type check runs before the runner is installed");
  assert.ok(at(this.ci, "tsc --noEmit") < at(this.ci, "bash tests/run.sh"));
});
Then("it validates the plugin strictly before it runs the tests", function (this: World) {
  assert.ok(at(this.ci, "claude plugin validate plugin --strict") < at(this.ci, "bash tests/run.sh"));
});
Then("it validates the marketplace before it runs the tests", function (this: World) {
  assert.ok(at(this.ci, "claude plugin validate .\n") < at(this.ci, "bash tests/run.sh"));
});
Then("it runs on every pull request", function (this: World) {
  assert.ok(/^on:\n(?:.*\n)*?\s+pull_request:\s*\n/m.test(this.ci), "no pull_request trigger");
  assert.ok(!/pull_request:\s*\n\s+branches:/.test(this.ci), "pull requests are filtered by branch");
});

Then("it runs on pushes", function (this: World) { at(this.ci, "push:"); });
Then("it runs on pull requests", function (this: World) { at(this.ci, "pull_request:"); });
Then("it has a job named {string}", function (this: World, name: string) {
  assert.ok(new RegExp(`^  ${name}:\\s*$`, "m").test(this.ci), `no job named ${name}`);
});
Then("it checks out the repository", function (this: World) { at(this.ci, "actions/checkout@"); });
Then("it runs the test suite", function (this: World) { at(this.ci, "bash tests/run.sh"); });
Then("it runs the release check only for pull requests whose title starts with {string}", function (this: World, prefix: string) {
  at(this.ci, `startsWith(github.event.pull_request.title, '${prefix}')`);
  at(this.ci, "tests/check_release.sh");
});
