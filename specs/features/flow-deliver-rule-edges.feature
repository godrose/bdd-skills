@flow-deliver
Feature: The deliver rules read the report the way the product manager would

  The rules are counted on the saved transcript. These scenarios pin the edges that the older ones leave open: what counts as a developer line, which changes are allowed, how a range of examples is read, and which test counts make the report suspect.

  Decision (2026-11-12): Added from the mutation survivors of the deliver harness. Why: each scenario here fails when the matching line of `flows/rules.pl` is broken.
  Decision (2026-11-12): The words of the report title and of the compare header are not pinned. Why: they are wording. No rule reads them.

  Rule: A developer line may name files and code

    Scenario: A paragraph that starts with "For the developer" is not a break of plain words
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late.

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: passed

        For the developer
        The steps live in `steps/loans.steps.js` and the page in src/pages/loans.html.
        """
      When the harness plays the conversation
      Then the rule "plain-words" is held

    Scenario: A developer sentence in the middle of a line is not a break of plain words
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late. For the developer: the steps are in steps/loans.steps.js.

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: passed
        """
      When the harness plays the conversation
      Then the rule "plain-words" is held

  Rule: A leak of code or files in the plain report is a break

    Scenario Outline: <what>
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: <text>

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: passed
        """
      When the harness plays the conversation
      Then the rule "plain-words" is broken

      Examples:
        | what                  | text                                |
        | a path to a document  | The notes are in docs/notes.md.     |
        | a script file name    | Open show.js to see the page.       |
        | a constant in a span  | The value is `DAYS_LATE`.           |
        | a camel case name     | The value is `daysLate`.            |
        | a function call       | The page calls `render()`.          |

    Scenario: A literal value in a code span is not a break
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: The notice reads `3 days late`.

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: passed
        """
      When the harness plays the conversation
      Then the rule "plain-words" is held

  Rule: Only some project changes are allowed in a deliver run

    Scenario Outline: A change to <file> is allowed
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      And the assistant writes "<file>" while it says message 3
      When the harness plays the conversation
      Then the rule "project-untouched" is held

      Examples:
        | file                    |
        | src/extra.js            |
        | docs/out-of-scope.md    |
        | docs/decisions/log.jsonl |

    Scenario Outline: A change to <file> is not allowed
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      And the assistant writes "<file>" while it says message 3
      When the harness plays the conversation
      Then the rule "project-untouched" is broken

      Examples:
        | file         |
        | docs/other.md |
        | README.md    |

  Rule: A third message that asks for approval is counted however it is worded

    Scenario Outline: A question that says "<words>" counts as an ask
      Given the assistant says the checklist and then the scenarios
      And the assistant says:
        """
        <question>
        """
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "approval-asked-once" is broken

      Examples:
        | words    | question                         |
        | go ahead | Can we go ahead with the wording? |
        | go-ahead | Do you give a go-ahead?          |

  Rule: The report must be about every example, and parked examples are not passed

    Scenario: A failed example has its line and needs no Not checked section
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late.

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: failed - the notice scrolls away

        Regression: 1 earlier scenario still passes.
        Seen: opened the loans page on the same data.
        """
      When the harness plays the conversation
      Then the rule "report-shape" is held

    Scenario: "could not be checked" counts as parked
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late.

        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: could not be checked - needs a real browser

        Regression: 1 earlier scenario still passes.
        Seen: opened the loans page on the same data.

        Not checked, and what it risks:
        - E2 Members may scroll past the notice and miss it.
        """
      When the harness plays the conversation
      Then the rule "report-shape" is held

    Scenario: A report with no Delivered line breaks the shape
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        E1 A late loan shows how many days late it is: passed
        E2 The notice stays in view when the member scrolls: passed

        Regression: 1 earlier scenario still passes.
        Seen: opened the loans page on the same data.
        """
      When the harness plays the conversation
      Then the rule "report-shape" is broken
      And the detail of the rules mentions "no Delivered line"

    Scenario Outline: A range "<range>" in the Not checked section names every example in it
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late.

        E1 A late loan shows how many days late it is: couldn't be checked - needs a real browser
        E2 The notice stays in view when the member scrolls: passed
        E3 The notice names the book: couldn't be checked - needs a real browser

        Regression: 1 earlier scenario still passes.
        Seen: opened the loans page on the same data.

        Not checked, and what it risks:
        - <range> Members may miss the notice.
        """
      When the harness plays the conversation
      Then the rule "parked-not-passed" is broken
      And the detail of the rules mentions "E2"

      Examples:
        | range   |
        | E1 to E3 |
        | E1-E3   |
        | E1 to 3 |

    Scenario: Two examples named one by one leave the one between them alone
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with:
        """
        Delivered: A late loan shows its days late.

        E1 A late loan shows how many days late it is: couldn't be checked - needs a real browser
        E2 The notice stays in view when the member scrolls: passed
        E3 The notice names the book: couldn't be checked - needs a real browser

        Regression: 1 earlier scenario still passes.
        Seen: opened the loans page on the same data.

        Not checked, and what it risks:
        - E1 and E3 Members may miss the notice.
        """
      When the harness plays the conversation
      Then the rule "parked-not-passed" is held

  Rule: A report that says everything passed is checked against the saved test output

    Scenario: No saved test output is a break
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      When the rules are counted on a run folder with no saved test output
      Then the rule "never-reported-passed" is broken
      And the detail of the rules mentions "no saved test output"

    Scenario Outline: A test run that shows <count> is not a pass
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      And the test run reports:
        """
        <output>
        """
      When the harness plays the conversation
      Then the rule "never-reported-passed" is broken

      Examples:
        | count         | output                                   |
        | a failure     | 2 scenarios (1 failed, 1 passed)         |
        | a skipped one | 2 scenarios (1 skipped, 1 passed)        |
        | an undefined  | 2 scenarios (1 undefined, 1 passed)      |
        | an ambiguous  | 2 scenarios (1 ambiguous, 1 passed)      |

    Scenario: A test run that passed everything is not a break
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      And the test run reports:
        """
        2 scenarios (2 passed)
        6 steps (6 passed)
        """
      When the harness plays the conversation
      Then the rule "never-reported-passed" is held
