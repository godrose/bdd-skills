@flow-deliver
Feature: Fixture c is a small project the harness can run deliver on

  Decision (2026-11-11): The page script runs in the real fixture folder, and a loans file a scenario writes there is removed after it. Why: the old file did the same, and the refusal check needs the real path depth.

  Scenario: The fixture pins its runner with a lockfile
    Given the file "flows/fixtures/c/project/package.json"
    Then it contains '"@cucumber/cucumber": "11.3.0"'
    And these files exist:
      | flows/fixtures/c/project/package-lock.json |

  Scenario: The fixture has two stories
    Then these files exist:
      | flows/fixtures/c/story-1.txt |
      | flows/fixtures/c/story-2.txt |

  Scenario: The second story is about a notice that stays in view
    Given the file "flows/fixtures/c/story-2.txt"
    Then it contains "stays in view"

  Scenario: The persona gives the approvals
    Given the file "flows/personas/approver.md"
    Then it contains "Approved"

  Scenario: The fixture has one scenario
    Given the feature files of the fixture project
    Then they hold 1 scenario

  Scenario: The fixture can show its page
    Then these files exist:
      | flows/fixtures/c/project/src/show.js     |
      | flows/fixtures/c/project/data/loans.json |

  Scenario: The page is built from the loans data
    When the page script of the fixture is run
    Then the output mentions:
      | My loans |
      | Dune     |
      | overdue  |

  Scenario: No fixed page is left next to the script
    Then the file "flows/fixtures/c/project/src/pages/loans.html" does not exist

  Scenario: The config of the fixture does not name a fixed page
    Given the file "flows/fixtures/c/project/.claude/bdd-config.md"
    Then it does not contain "loans.html"
    And it does not contain ".html"
    And it does not contain "pages"

  Scenario: The page script shows the loans file it is given
    Given a loans file "data/_t.json" in the fixture that holds:
      """
      [{"id":1,"book":"Emma","borrowedDaysAgo":3,"status":"open"}]
      """
    When the page script of the fixture is run on "data/_t.json"
    Then the output mentions "Emma"

  Scenario: A loan of 3 days is not shown as overdue
    Given a loans file "data/_t.json" in the fixture that holds:
      """
      [{"id":1,"book":"Emma","borrowedDaysAgo":3,"status":"open"}]
      """
    When the page script of the fixture is run on "data/_t.json"
    Then the output does not mention "overdue"

  Scenario: The page script refuses a file outside the data folder
    When the page script of the fixture is run on "../../../package.json"
    Then the run fails
    And the output mentions "data"
