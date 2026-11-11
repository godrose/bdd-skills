// Helpers shared by the step definitions.
import fs from "node:fs";
import path from "node:path";

export const ROOT = path.resolve(__dirname, "../..");
export const read = (rel: string): string => fs.readFileSync(path.join(ROOT, rel), "utf8").replace(/\r\n/g, "\n");

// What a step remembers for the steps after it, within one scenario.
export type World = {
  dir: string;
  bin: string;
  log: string;
  status: number | null;
  output: string;
  ci: string;
  subject: string;
  files: string[];
  kept: string;
  run: { args: string[]; env: NodeJS.ProcessEnv } | null;
};
