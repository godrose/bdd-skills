// Prints the file a user downloads with Export, for a filter.
// It reads data/records.json and the filter in data/filter.json, or other files under data/ given as the first and second argument.
const path = require("path");
const { exportCsv } = require("./export");
const dataDir = path.resolve(__dirname, "../data");
function inData(arg, fallback) {
  const file = arg ? path.resolve(process.cwd(), arg) : path.join(dataDir, fallback);
  const rel = path.relative(dataDir, file);
  if (rel.startsWith("..") || path.isAbsolute(rel)) {
    console.error("show.js reads only files under data/");
    process.exit(1);
  }
  return file;
}
const records = require(inData(process.argv[2], "records.json"));
const filter = require(inData(process.argv[3], "filter.json"));
process.stdout.write(exportCsv(records, filter));
