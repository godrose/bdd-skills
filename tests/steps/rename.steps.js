const { Given, Then } = require("@cucumber/cucumber");
const assert = require("assert");
const { read, textFiles } = require("./support");

// The old name, written in two parts so that this file does not name it.
const OLD_NAME = new RegExp("godrose" + "/bdd($|[^-A-Za-z0-9]|-[^s])", "m");

Given("the files of the repo, apart from the docs and the installed dependencies", function () {
  this.files = textFiles([".git", "docs", "node_modules"]);
});

Then("none of them names the repo by its old name", function () {
  const hits = this.files.filter((f) => read(f).split("\n").some((line) => OLD_NAME.test(line)));
  assert.deepStrictEqual(hits, [], "old repo name in: " + hits.join(", "));
});

Then("the README tells a reader the repo is bdd-skills and the plugin is bdd", function () {
  assert.ok(read("README.md").includes("The repo is `bdd-skills`. The plugin is `bdd`, so its commands are `/bdd:*`."));
});

const PLACES = {
  "the README install command": ["README.md", "/plugin marketplace add godrose/bdd-skills"],
  "the installer": ["install.sh", 'REPO_URL="https://github.com/godrose/bdd-skills"'],
  "the plugin manifest": ["plugin/.claude-plugin/plugin.json", '"repository": "https://github.com/godrose/bdd-skills"'],
  "the init command's source line": ["plugin/commands/init.md", "# Source: https://github.com/godrose/bdd-skills"],
};

Then(/^(.+) points to the repo bdd-skills$/, function (place) {
  const [file, text] = PLACES[place] || assert.fail("unknown place: " + place);
  assert.ok(read(file).includes(text), `${file} lacks: ${text}`);
});
