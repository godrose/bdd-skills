const { Given, When, Then } = require("@cucumber/cucumber");
const { markOverdue } = require("../src/jobs/markOverdue");
let loans = [];
Given("a member borrowed a book {int} days ago", (days) => { loans = [{ id: 1, borrowedDaysAgo: days, status: "open" }]; });
When("the nightly check runs", () => { loans = markOverdue(loans); });
Then("the loan status is {string}", (status) => { if (loans[0].status !== status) throw new Error(loans[0].status); });
