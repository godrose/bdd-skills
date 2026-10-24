# Dry run: bdd-discover and bdd-design --specify-only

Run on 2026-10-24 in a scratch project with the skills installed by `install.sh`. The `.claude/bdd-config.md` was the unfilled template. Both runs were headless (`claude -p`). Output is excerpted.

## 1. `/bdd-discover` on `tests/fixtures/story.md`

The story has two vague acceptance criteria ("The export works", "The file opens in a spreadsheet").

Expected: report that there is nothing to mine, refuse to guess, ask one question, write no scenarios.

Result:

> Nothing to mine. The config still holds only template placeholders, and there are no `.feature` files. I'll skip the vocabulary and lint steps for now and work from the story text.
>
> The acceptance criteria are too vague to write scenarios from. "The export works" says nothing about what is in the file. "Opens in a spreadsheet" doesn't name a format. I won't guess at either.
>
> **Question 1.** Is that reading right? In particular, is the file for the accountant to read and work with, and not for importing back into the shop?

## 2. `/bdd-design --specify-only` with the answers supplied

Prompt: CSV file, columns order id, date, customer, total, one row per order, opens in a spreadsheet, an empty list gives only the header row. Features dir `features/`. Scenarios pre-approved.

Expected: `.feature` files tagged `@manual`, a spec summary, no implementer.

Result (excerpt):

> I wrote six scenarios, all tagged `@manual`, plus a spec PR summary. I haven't run or automated anything.
>
> - `features/order-export.feature`
> - `features/order-export.spec-summary.md`
>
> To automate them once approved, run `/bdd-implement features/order-export.feature`.

The summary file had the sections Story to scenarios, Cases included, Cases deliberately excluded, New terms, Step status.

This run happened before the review fixes. After them, `bdd-design` also runs **generate** once in `specify-only` mode and reports undefined steps. It was not re-run headlessly.
