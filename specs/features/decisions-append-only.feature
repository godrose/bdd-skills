@decisions
Feature: A decision log only grows

  The check against a base ref fails when a record that was committed is edited or removed. New records and new files pass. Parallel appends merge.

  Decision (2026-11-11): The union-merge scenario is kept although it tests git. Why: the builder named merging parallel appends as a group.

  Scenario: First adoption passes when the base has no decisions folder
    Given a project with the header row scenario
    And the decisions folder is missing
    And the project is committed
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked against the base "HEAD"
    Then the script exits with status 0

  Scenario: A log committed with Windows line endings passes against the same log with Unix endings
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" is rewritten with Windows line endings
    And the project is committed
    And the log "S" is rewritten with Unix line endings
    When the log is checked against the base "HEAD"
    Then the script exits with status 0

  Scenario: Outside a git repository the script exits 2
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked against the base "HEAD"
    Then the script exits with status 2
    And the output mentions "--base needs a git repository"

  Rule: A log that is already committed

    Background:
      Given a project with the header row scenario
      And the log "S" gets these decisions:
        | id   | at         | text                    | effect                                      |
        | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
      And the project is committed

    Scenario: Appending a record passes
      Given the log "S" gets these decisions:
        | id   | at         | text                  |
        | S-02 | 2026-11-01 | Dates use one format. |
      When the log is checked against the base "HEAD"
      Then the script exits with status 0

    Scenario: Editing a record fails and names the file and line
      Given the word "exported" is changed to "exportxd" in the log "S"
      When the log is checked against the base "HEAD"
      Then the script exits with status 1
      And the output mentions:
        | ERROR E-APPEND |
        | S.jsonl:1      |

    Scenario: Emptying a log file fails
      Given the log "S" is emptied
      When the log is checked against the base "HEAD"
      Then the output mentions:
        | ERROR E-APPEND |
        | S.jsonl:1      |

    Scenario: Deleting the first line of a log fails
      Given the log "S" gets these decisions:
        | id   | at         | text                  |
        | S-02 | 2026-11-01 | Dates use one format. |
      And the first line of the log "S" is deleted
      When the log is checked against the base "HEAD"
      Then the output mentions "ERROR E-APPEND"

    Scenario: Deleting a log file fails
      Given the log "S" is deleted
      When the log is checked against the base "HEAD"
      Then the output mentions "ERROR E-APPEND"

    Scenario: A new log file passes
      Given the log "T" gets these decisions:
        | id   | at         | text         |
        | T-01 | 2026-11-01 | Other story. |
      When the log is checked against the base "HEAD"
      Then the script exits with status 0

    Scenario: An unknown base ref exits 2
      When the log is checked against the base "no-such-ref"
      Then the script exits with status 2

    Scenario: Parallel appends on two branches merge with no conflict under the union rule
      Given the git attributes merge the log files by union
      And a branch "a" cut from the main branch where the log "S" gets these decisions:
        | id   | at         | text                  |
        | S-02 | 2026-11-01 | Dates use one format. |
      And a branch "b" cut from the main branch where the log "S" gets these decisions:
        | id   | at         | text   |
        | S-03 | 2026-11-01 | Third. |
      When the branches "a" and "b" are merged into the main branch, one after the other
      Then the merge has no conflict
      And the log "S" has 3 lines
