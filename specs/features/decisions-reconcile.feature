@decisions
Feature: Live decisions and findings when reconciling

  The check lines up the live decisions with the scenarios. A decision about a scenario that is gone is an error. A changed or undecided scenario is a warning.

  Decision (2026-11-11): The scope scenarios with a base ref sit here. Why: they decide which findings appear.

  Scenario: A healthy log passes with no warnings
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                              |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (as it is now) |
    When the log is checked
    Then the script exits with status 0
    And the output mentions "summary errors=0 warnings=0"

  Scenario: A decision about a scenario that does not exist fails as an orphan
    Given a project with no scenarios
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked
    Then the script exits with status 1
    And the output mentions "ERROR E-ORPHAN"

  Scenario: A removed scenario is not an orphan and not undecided
    Given a project with no scenarios
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
      | S-02 | 2026-11-01 | Header row is removed.  | removes spec-header-row                     |
    When the log is checked
    Then the script exits with status 0
    And the output does not mention "E-ORPHAN"
    And the output does not mention "W-UNDECIDED"

  Scenario: A scenario that still exists after its removal gets an undecided warning
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
      | S-02 | 2026-11-01 | Header row is removed.  | removes spec-header-row                     |
    When the log is checked
    Then the output mentions "WARN W-UNDECIDED"

  Scenario: A changed scenario is a drift warning and a rewording decision clears it
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                              |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (as it is now) |
    And the text "I export it" is replaced by "I export the list" in the feature file "export.feature"
    When the log is checked
    Then the script exits with status 0
    And the output mentions "WARN W-DRIFT"
    Given the log "S" gets these decisions:
      | id   | at         | text         | effect                                 |
      | S-02 | 2026-11-01 | New wording. | rewords spec-header-row (as it is now) |
    When the log is checked
    Then the output does not mention "W-DRIFT"

  Scenario: A superseded decision is not live
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                 | supersedes |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-gone (fingerprint aaaaaaaa)  |            |
      | S-02 | 2026-11-01 | Header row changes.     | changes spec-header-row (as it is now) | S-01       |
    When the log is checked
    Then the script exits with status 0
    And the output does not mention "E-ORPHAN"

  Scenario: Two decisions that supersede the same decision give a conflict warning
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                 | supersedes |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (as it is now)    |            |
      | S-02 | 2026-11-01 | Header row changes.     | changes spec-header-row (as it is now) | S-01       |
      | S-03 | 2026-11-02 | Another view.           |                                        | S-01       |
    When the log is checked
    Then the output mentions "WARN W-CONFLICT"

  Scenario: A scenario with no decision gets an undecided warning
    Given a project with the header row scenario
    When the log is checked
    Then the script exits with status 0
    And the output mentions "WARN W-UNDECIDED"

  Scenario: Scenarios without an id are counted as legacy
    Given the feature file "a.feature" reads:
      ```
      Feature: Legacy
        Scenario: One
          Given a
        Scenario: Two
          Given b
        @spec-x
        Scenario: Three
          Given c
      ```
    When the log is checked
    Then the output mentions "I-LEGACY 2"

  Scenario: A duplicate scenario tag fails
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        @spec-header-row
        Scenario: One
          Given a
        @spec-header-row
        Scenario: Two
          Given b
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions "ERROR E-DUP-SCENARIO"

  Scenario: Exclude, defer and rationale decisions pass
    Given a project with no scenarios
    And the log "S" gets these decisions:
      | id   | at         | text       | effect                               |
      | S-01 | 2026-10-31 | Text S-01. | excludes partial exports             |
      | S-02 | 2026-10-31 | Text S-02. | defers large exports (reason: later) |
      | S-03 | 2026-10-31 | Text S-03. |                                      |
    When the log is checked
    Then the script exits with status 0
    And the output mentions "summary errors=0 warnings=0"

  Scenario: An open item with a resolving decision passes
    Given a project with no scenarios
    And the log "S" gets the open question "S-01" dated "2026-10-30": "One column or two?"
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-02","kind":"decision","story":"S","at":"2026-10-31","text":"Text S-02.","effects":[],"resolves":["S-01"]}
      ```
    When the log is checked
    Then the script exits with status 0
    And the output mentions "summary errors=0 warnings=0"

  Rule: Two stories, each with its own log, committed

    Background:
      Given a project with no scenarios
      And the feature file "a.feature" reads:
        ```
        Feature: A
          @spec-a
          Scenario: A
            Given a
        ```
      And the feature file "b.feature" reads:
        ```
        Feature: B
          @spec-b
          Scenario: B
            Given b
        ```
      And the log "A" gets these decisions:
        | id   | at         | text | effect                             |
        | A-01 | 2026-10-31 | A.   | adds spec-a (fingerprint bbbbbbbb) |
      And the log "B" gets these decisions:
        | id   | at         | text | effect                     |
        | B-01 | 2026-10-31 | B.   | adds spec-b (as it is now) |
      And the project is committed

    Scenario: With a base ref only the stories that changed are checked for drift
      Given the log "B" gets these decisions:
        | id   | at         | text    |
        | B-02 | 2026-11-01 | More B. |
      When the log is checked against the base "HEAD"
      Then the output does not mention "W-DRIFT"

    Scenario: Without a base ref every story is checked for drift
      Given the log "B" gets these decisions:
        | id   | at         | text    |
        | B-02 | 2026-11-01 | More B. |
      When the log is checked
      Then the output mentions "WARN W-DRIFT"

    Scenario: With a base ref a deleted feature file gives an orphan
      Given the feature file "a.feature" is deleted
      When the log is checked against the base "HEAD"
      Then the output mentions "ERROR E-ORPHAN"

    Scenario: With a base ref a changed scenario is drift
      Given the text "Given a" is replaced by "Given a changed" in the feature file "a.feature"
      When the log is checked against the base "HEAD"
      Then the output mentions "WARN W-DRIFT"
