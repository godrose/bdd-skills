// Runs every night. A loan open for more than 14 days becomes overdue.
const LIMIT_DAYS = 14;
function markOverdue(loans) {
  return loans.map((l) => (l.status === "open" && l.borrowedDaysAgo > LIMIT_DAYS ? { ...l, status: "overdue" } : l));
}
module.exports = { markOverdue };
