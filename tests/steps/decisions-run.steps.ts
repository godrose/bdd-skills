import { When } from "@cucumber/cucumber";
import type { World } from "./support";
import { git, gitRun, run } from "./decisions-support";

const CHECK = ["check", "--dir", "docs/decisions", "--features", "features"];
const words = (options: string): string[] => options.split(" ");

When("the log is checked", function (this: World) { run(this, CHECK); });
When("the log is checked against the base {string}", function (this: World, ref: string) { run(this, [...CHECK, "--base", ref]); });
When("the log is checked without jq", function (this: World) { run(this, ["check"], { PATH: "/nonexistent" }); });
When("the log is checked with only the environment naming the folder {string}", function (this: World, folder: string) {
  run(this, ["check", "--features", "features"], { BDD_DECISIONS_DIR: folder });
});
When("the log is checked with the environment naming the folder {string} and the flag naming the folder {string}", function (this: World, env: string, flag: string) {
  run(this, ["check", "--dir", flag, "--features", "features"], { BDD_DECISIONS_DIR: env });
});
When("the log is checked with no folder given", function (this: World) { run(this, ["check", "--features", "features"]); });

When("the fingerprint of {string} is asked for", function (this: World, id: string) { run(this, ["fingerprint", id, "--features", "features"]); });
When("the fingerprint of {string} is asked for without a features folder", function (this: World, id: string) { run(this, ["fingerprint", id]); });

When("the status of {string} is asked for", function (this: World, id: string) { run(this, ["status", id, "--features", "features"]); });
When("the status of {string} is asked for with the options {string}", function (this: World, id: string, options: string) {
  run(this, ["status", id, "--features", "features", ...words(options)]);
});

const SHOW = (story: string): string[] => ["show", story, "--dir", "docs/decisions"];
When("the story {string} is shown", function (this: World, story: string) { run(this, [...SHOW(story), "--features", "features"]); });
When("the story {string} is shown with the options {string}", function (this: World, story: string, options: string) {
  run(this, [...SHOW(story), "--features", "features", ...words(options)]);
});
When("the story {string} is shown without a features folder", function (this: World, story: string) { run(this, SHOW(story)); });
When("the story {string} is shown with the options {string}, without a features folder", function (this: World, story: string, options: string) {
  run(this, [...SHOW(story), ...words(options)]);
});

When("the branches {string} and {string} are merged into the main branch, one after the other", function (this: World, first: string, second: string) {
  git(this, "checkout", "-q", "main");
  const a = gitRun(this, "merge", "-q", first);
  const b = gitRun(this, "merge", "-q", "--no-edit", second);
  this.status = a.status !== 0 ? a.status : b.status;
});
