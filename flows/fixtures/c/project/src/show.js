// Prints the loans page a member sees, after the nightly check.
// It reads data/loans.json, or another loans file under data/ given as the first argument.
const path = require("path");
const { markOverdue } = require("./jobs/markOverdue");
const { renderLoansPage } = require("./pages/loans");
const dataDir = path.resolve(__dirname, "../data");
const file = process.argv[2] ? path.resolve(process.cwd(), process.argv[2]) : path.join(dataDir, "loans.json");
const rel = path.relative(dataDir, file);
if (rel.startsWith("..") || path.isAbsolute(rel)) {
  console.error("show.js reads only files under data/");
  process.exit(1);
}
process.stdout.write(renderLoansPage(markOverdue(require(file))));
