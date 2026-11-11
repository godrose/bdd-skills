const { Given, Then } = require("@cucumber/cucumber");
const assert = require("assert");
const { read } = require("./support");

const at = (text, needle) => { const i = text.indexOf(needle); assert.ok(i >= 0, "the CI workflow lacks: " + needle); return i; };

Given("the CI workflow", function () { this.ci = read(".github/workflows/ci.yml"); });
Then("it installs the scenario runner before it runs the tests", function () {
  assert.ok(at(this.ci, "npm ci") < at(this.ci, "bash tests/run.sh"));
});
Then("it validates the plugin strictly before it runs the tests", function () {
  assert.ok(at(this.ci, "claude plugin validate plugin --strict") < at(this.ci, "bash tests/run.sh"));
});
Then("it validates the marketplace before it runs the tests", function () {
  assert.ok(at(this.ci, "claude plugin validate .\n") < at(this.ci, "bash tests/run.sh"));
});
Then("it runs on every pull request", function () {
  assert.ok(/^on:\n(?:.*\n)*?\s+pull_request:\s*\n/m.test(this.ci), "no pull_request trigger");
  assert.ok(!/pull_request:\s*\n\s+branches:/.test(this.ci), "pull requests are filtered by branch");
});
