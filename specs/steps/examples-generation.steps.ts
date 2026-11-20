import { Then } from "@cucumber/cucumber";
import assert from "node:assert";
import crypto from "node:crypto";
import { read, type World } from "./support";

Then("the SHA-256 after {string} is the SHA-256 of {string}", function (this: World, label: string, rel: string) {
  const at = this.subject.indexOf(label);
  assert.ok(at >= 0, `the text has no "${label}"`);
  const written = this.subject.slice(at + label.length).match(/[0-9a-f]{64}/)?.[0];
  assert.ok(written, `no SHA-256 after "${label}"`);
  const actual = crypto.createHash("sha256").update(read(rel)).digest("hex");
  assert.strictEqual(written, actual, `the text says ${written}, ${rel} is ${actual}`);
});
