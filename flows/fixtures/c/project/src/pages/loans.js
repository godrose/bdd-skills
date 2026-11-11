// Builds the loans page a member sees, from a list of loans.
function renderLoansPage(loans) {
  const rows = loans.map((l) => `  <tr><td>${l.book}</td><td>${l.borrowedDaysAgo} days ago</td><td>${l.status}</td></tr>`).join("\n");
  return `<h1>My loans</h1>\n<table>\n  <tr><th>Book</th><th>Borrowed</th><th>Status</th></tr>\n${rows}\n</table>\n`;
}
module.exports = { renderLoansPage };
