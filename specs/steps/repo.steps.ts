import { Given, Then } from "@cucumber/cucumber";
import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { ROOT, read, type World } from "./support";

const has = (w: World, text: string): void => assert.ok(w.subject.includes(text), `lacks: ${text}`);
const hasNot = (w: World, text: string): void => assert.ok(!w.subject.includes(text), `has: ${text}`);

Given("the pull request template", function (this: World) { this.subject = read(".github/pull_request_template.md"); });
Then("it has a summary section", function (this: World) { has(this, "## Summary"); });
Then("it asks whether the test suite is green", function (this: World) { has(this, "bash tests/run.sh"); });
Then("it asks whether the tests failed before the change", function (this: World) { has(this, "Tests failed before the change"); });
Then("it asks for no project names in the diff", function (this: World) { has(this, "No project names"); });
Then("it asks for no session links", function (this: World) { has(this, "No session links"); });
Then("it has a box for release pull requests", function (this: World) { has(this, "Release PR"); });

Given("the code owners file", function (this: World) { this.subject = read(".github/CODEOWNERS"); });
Then("it makes {string} the owner of every file", function (this: World, owner: string) { has(this, `* @${owner}`); });

Given("the Dependabot configuration", function (this: World) { this.subject = read(".github/dependabot.yml"); });
Then("it keeps the GitHub Actions up to date", function (this: World) { has(this, "package-ecosystem: github-actions"); });
Then("it checks every week", function (this: World) { has(this, "interval: weekly"); });

// The text it looks for is written in two parts, so that this file does not contain it.
const BAD_SED = "sed -i " + "''";
Given("the shell scripts of the tests, the installer and the plugin", function (this: World) {
  const list = (dir: string): string[] =>
    fs.existsSync(path.join(ROOT, dir)) ? fs.readdirSync(path.join(ROOT, dir)).filter((f) => f.endsWith(".sh")).map((f) => path.join(dir, f)) : [];
  this.files = [...list("tests").filter((f) => path.basename(f).startsWith("test_")), ...list("plugin/scripts"), "install.sh"];
});
Then("none of them uses sed -i with an empty suffix", function (this: World) {
  const bad = this.files.filter((f) => read(f).includes(BAD_SED));
  assert.deepStrictEqual(bad, [], "GNU sed reads the empty string as a file name: " + bad.join(", "));
});

Given("the contributor guide", function (this: World) { this.subject = read("CLAUDE.md"); });
Then("it has a releasing section", function (this: World) { has(this, "## Releasing"); });
Then("it no longer has the pre-launch section", function (this: World) { hasNot(this, "## Before going public"); });
Then("it no longer says that every change needs a version bump", function (this: World) { hasNot(this, "needs a plugin version bump"); });

Given("the README", function (this: World) { this.subject = read("README.md"); });
Then("it does not say that every merge is a new version", function (this: World) { hasNot(this, "each merge to `main` is a new version"); });
Then("it points to the changelog", function (this: World) { has(this, "CHANGELOG.md"); });

Given("the docs index", function (this: World) { this.subject = read("docs/README.md"); });
Then("every discovery pack is listed in it", function (this: World) {
  const packs = fs.readdirSync(path.join(ROOT, "docs/discovery")).filter((f) => f.endsWith(".md"));
  const missing = packs.filter((p) => !this.subject.includes(p));
  assert.deepStrictEqual(missing, [], "not in the index: " + missing.join(", "));
});
