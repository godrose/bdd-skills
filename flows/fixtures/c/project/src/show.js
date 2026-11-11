// Prints the loans page a member sees: the loans in data/loans.json, after the nightly check.
const loans = require("../data/loans.json");
const { markOverdue } = require("./jobs/markOverdue");
const { renderLoansPage } = require("./pages/loans");
process.stdout.write(renderLoansPage(markOverdue(loans)));
