import { Given, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import { read, type World } from "./support";

const at = (text: string, needle: string): number => {
  const i = text.indexOf(needle);
  assert.ok(i >= 0, "the CI workflow lacks: " + needle);
  return i;
};

Given("the CI workflow", function (this: World) { this.ci = read(".github/workflows/ci.yml"); });
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
