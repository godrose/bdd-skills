@decisions
Feature: Showing the agreed behavior of a story

  The show command turns a story's log into a page a product manager can read: what was agreed, what was left out, what is open and the history.

  Decision (2026-11-11): Record ids and fingerprints never appear on the page. Why: from code, the page is for readers of the product, not the log.

  Rule: A story with agreed behavior, exclusions, open questions and replaced wording

    Background:
      Given a project with no scenarios
      And the feature file "s.feature" reads:
        ```
        Feature: F
          @spec-a @pending
          Scenario: A
            Given a
          @spec-b @manual-only
          Scenario: B
            Given b
          @spec-c
          Scenario: C
            Given c
        ```
      And the log "S" gets these decisions:
        | id   | at         | text                 | effect                     |
        | S-01 | 2026-10-01 | Alpha is exported.   | adds spec-a (as it is now) |
        | S-02 | 2026-10-02 | Bravo is checked.    | adds spec-b (as it is now) |
        | S-03 | 2026-10-03 | Charlie is exported. | adds spec-c (as it is now) |
        | S-04 | 2026-10-04 | No audit trail.      | excludes audit             |
      And the decision "S-01" in the log "S" has the source of kind "slack" with the reference "https://s/1" and the role "agreed"
      And the log "S" gets the open question "S-05" dated "2026-10-05": "Who owns retention?"
      And the log "S" gets the open question "S-06" dated "2026-10-05": "Resolved question?"
      And the log "S" gets these decisions:
        | id   | at         | text                      | supersedes | resolves |
        | S-07 | 2026-10-06 | Retention is ninety days. |            | S-06     |
        | S-08 | 2026-10-07 | Old wording.              |            |          |
        | S-09 | 2026-10-08 | New wording.              | S-08       |          |

    Scenario: The page has a headline and its four sections in order
      When the story "S" is shown
      Then the script exits with status 0
      And the output mentions "# Agreed behavior: S"
      And the output lists these in order:
        | ## What we agreed                  |
        | ## Left out, postponed or accepted |
        | ## Still open                      |
        | ## History                         |

    Scenario: Each agreed line carries its status and its source
      When the story "S" is shown
      Then the output mentions:
        | Alpha is exported. (planned) ([source](https://s/1)) |
        | Bravo is checked. (checked by hand)                  |
        | Charlie is exported. (automated)                     |

    Scenario: No record ids and no fingerprints appear
      When the story "S" is shown
      Then the output does not mention "S-01"
      And the output does not mention the fingerprint of "spec-a"

    Scenario: A resolved open question is not listed as open and an unresolved one is
      When the story "S" is shown
      Then the section "## Still open" does not mention "Resolved question?"
      And the output mentions "Who owns retention?"

    Scenario: A replaced decision and a closed question appear only in the history
      When the story "S" is shown
      Then the section "## History" mentions "Old wording. (replaced on 2026-10-08)"
      And the output above "## History" does not mention "Old wording."
      And the section "## History" mentions "Resolved question? (closed)"

    Scenario: The output is the same when it is shown again
      When the story "S" is shown
      Then showing it again gives the same output

    Scenario: Outside a git repository the page says so
      When the story "S" is shown
      Then the output mentions "not in a git repository"

    Scenario: A channel link is shown as the discussion
      When the story "S" is shown with the options "--channel https://x/c"
      Then the output mentions "Discussion: https://x/c"

    Scenario: A story with no decisions exits 0 and says so
      When the story "NOPE" is shown
      Then the script exits with status 0
      And the output mentions "No decisions recorded for NOPE"

  Rule: A single decision with special characters

    Background:
      Given a project with no scenarios
      And the log "S" gets these decisions:
        | id   | at         | text                   |
        | S-01 | 2026-10-01 | A \| B *bold* "q" é 中 |

    Scenario: Special characters are kept as written
      When the story "S" is shown without a features folder
      Then the output mentions "A | B *bold* \"q\" é 中"

    Scenario: A story with nothing to list shows no empty sections
      When the story "S" is shown without a features folder
      Then the output does not mention "## Still open"
      And the output does not mention "## History"
      And the output mentions "Nothing agreed yet."

    Scenario: In a git repository the page names the commit and does not mention uncommitted changes
      Given the project is committed
      When the story "S" is shown without a features folder
      Then the output mentions "Generated from git at commit" and the short id of the last commit
      And the output does not mention "uncommitted changes"

    Scenario: With a since ref the page lists what changed since then
      Given the project is committed
      And the log "S" gets these decisions:
        | id   | at         | text           | effect            | supersedes |
        | S-02 | 2026-11-01 | Changed text.  |                   | S-01       |
        | S-03 | 2026-11-01 | Gone thing.    | removes spec-gone |            |
        | S-04 | 2026-11-01 | Skipped thing. | excludes x        |            |
        | S-05 | 2026-11-01 | Later thing.   | defers y          |            |
        | S-06 | 2026-11-01 | Plain thing.   |                   |            |
      When the story "S" is shown with the options "--since HEAD", without a features folder
      Then the output mentions:
        | ## Changed since you last looked                       |
        | Changed: Changed text. (was: A \| B *bold* "q" é 中)  |
        | Removed: Gone thing.                                   |
        | Left out: Skipped thing.                               |
        | Postponed: Later thing.                                |
        | Added: Plain thing.                                    |
        | uncommitted changes                                    |

    Scenario: Without a since ref the page has no changed-since section
      Given the project is committed
      And the log "S" gets these decisions:
        | id   | at         | text          | supersedes |
        | S-02 | 2026-11-01 | Changed text. | S-01       |
      When the story "S" is shown without a features folder
      Then the output does not mention "Changed since you last looked"

  Scenario: A source that is not a URL is shown as plain text, not as a broken link
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-a @pending
        Scenario: A
          Given a
      ```
    And the log "S" gets these decisions:
      | id   | at         | text               | effect                     |
      | S-01 | 2026-10-01 | Alpha is exported. | adds spec-a (as it is now) |
    And the decision "S-01" in the log "S" has the source of kind "slack" with the reference "Slack thread, Monday" and the role "agreed"
    When the story "S" is shown
    Then the script exits with status 0
    And the output mentions "Alpha is exported. (planned) (source: Slack thread, Monday)"
    And the output does not mention "[source]("

  Rule: Decisions about scenarios that are gone, blocked scenarios and text with line breaks

    Background:
      Given a project with no scenarios
      And the feature file "s.feature" reads:
        ```
        Feature: F
          @spec-d @blocked
          Scenario: D
            Given d
        ```
      And the log "S" gets these decisions:
        | id   | at         | text             | effect                       |
        | S-01 | 2026-10-01 | Gone is added.   | adds spec-gone (fingerprint cccccccc) |
        | S-02 | 2026-10-02 | Gone is removed. | removes spec-gone            |
        | S-03 | 2026-10-03 | D is agreed.     | adds spec-d (as it is now)   |
      And the log "S" gets these lines:
        ```
        {"v":1,"id":"S-04","kind":"decision","story":"S","at":"2026-10-04","text":"Line one\n   line two"}
        ```

    Scenario: A decision whose scenario was removed is closed and appears only in the history
      When the story "S" is shown
      Then the section "## History" mentions "Gone is added. (closed)"
      And the output above "## History" does not mention "Gone is added."

    Scenario: A blocked scenario is shown as waiting on the product
      When the story "S" is shown with the options "--blocked-tag @blocked"
      Then the output mentions "D is agreed. (waiting on the product)"

    Scenario: A line break in a decision text becomes a space
      When the story "S" is shown
      Then the output mentions "Line one line two"

  Rule: A decision that resolves an open question with a list of ids

    Background:
      Given a project with no scenarios
      And the log "S" gets the open question "S-05" dated "2026-10-05": "Who owns retention?"
      And the log "S" gets these lines:
        ```
        {"v":1,"id":"S-07","kind":"decision","story":"S","at":"2026-10-06","text":"Retention is ninety days.","resolves":["S-05"]}
        ```

    Scenario: The check accepts the list form
      When the log is checked
      Then the script exits with status 0

    Scenario: A question resolved through a list is not shown as still open
      When the story "S" is shown without a features folder
      Then the section "## History" mentions "Who owns retention? (closed)"
      And the output above "## History" does not mention "Who owns retention?"
