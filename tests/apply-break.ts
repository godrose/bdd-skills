// Applies one break to a file: a substitution written s, a delimiter, a pattern, the delimiter, a replacement, the delimiter and flags.
// The pattern is a JavaScript regular expression. Only the first match changes unless the flag g is given.
// In the replacement, $1 to $9 are captures, and \n \t \\ \$ and a backslash before the delimiter are a newline, a tab, a backslash, a dollar sign and the delimiter.
// Usage: apply-break.ts <file> <substitution>. Exits with 2 and a reason when the call or the substitution is not valid. The file is then not touched.
import fs from "node:fs";

const [file, sub] = process.argv.slice(2);

function fail(reason: string): never {
  process.stderr.write(`apply-break: ${reason}\n`);
  process.exit(2);
}

if (file === undefined || sub === undefined) fail("usage: apply-break.ts <file> <substitution>");
if (!fs.existsSync(file)) fail(`no such file: ${file}`);

if (sub[0] !== "s" || sub.length < 2 || /[A-Za-z0-9\s\\]/.test(sub[1])) fail(`not a substitution: "${sub}" must be s, a delimiter, a pattern, the delimiter, a replacement and the delimiter`);
const delim = sub[1];

const parts: string[] = [""];
for (let i = 2; i < sub.length; i++) {
  const c = sub[i];
  if (c === "\\" && i + 1 < sub.length) { parts[parts.length - 1] += c + sub[i + 1]; i++; continue; }
  if (c === delim && parts.length < 3) { parts.push(""); continue; }
  parts[parts.length - 1] += c;
}
if (parts.length < 3) fail(`not terminated: the substitution needs three ${delim}`);
const [pattern, template, flags] = parts;

const bad = [...flags].find((f) => !"gims".includes(f));
if (bad !== undefined) fail(`unknown flag: ${bad}. The flags are g, i, m and s`);

let re: RegExp;
try { re = new RegExp(pattern, flags); } catch (e) { fail(`not a valid pattern: ${(e as Error).message}`); }

type Piece = string | number;
const pieces: Piece[] = [];
let text = "";
for (let i = 0; i < template.length; i++) {
  const c = template[i];
  if (c === "\\" && i + 1 < template.length) {
    const n = template[i + 1];
    text += n === "n" ? "\n" : n === "t" ? "\t" : n === "\\" || n === "$" || n === delim ? n : c + n;
    i++;
  } else if (c === "$" && /[1-9]/.test(template[i + 1] ?? "")) {
    pieces.push(text, Number(template[i + 1]));
    text = "";
    i++;
  } else text += c;
}
pieces.push(text);

const before = fs.readFileSync(file, "utf8");
const after = before.replace(re, (...args: unknown[]) => {
  const captures = args.slice(1, args.findIndex((a, k) => k > 0 && typeof a === "number")) as (string | undefined)[];
  return pieces.map((p) => (typeof p === "number" ? captures[p - 1] ?? "" : p)).join("");
});
if (after !== before) fs.writeFileSync(file, after);
