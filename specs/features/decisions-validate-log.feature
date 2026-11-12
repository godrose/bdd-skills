@decisions
Feature: Validating a decision log

  A maintainer runs the check on the logs of a project. A bad record is named with its file and line. A valid log passes.

  Decision (2026-11-11): These scenarios move the checks of tests/test_decisions.sh and add none. Why: a migration adds no checks.

  Scenario: A valid log passes
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked
    Then the script exits with status 0
    And the output mentions "summary errors=0"

  Scenario: A line that is not JSON fails and is named with its line
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" gets these lines:
      ```
      {not json
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions:
      | ERROR E-JSON |
      | S.jsonl:2    |

  Scenario: A record with a missing field fails and names the field
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31"}
      ```
    When the log is checked
    Then the output mentions:
      | ERROR E-SCHEMA     |
      | missing field text |

  Scenario: A record from a newer format version fails and says to update the skills
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":2,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x"}
      ```
    When the log is checked
    Then the output mentions:
      | ERROR E-VERSION   |
      | update the skills |

  Scenario: An unknown effect kind fails
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x","effects":[{"op":"burns","scenario":"spec-header-row"}]}
      ```
    When the log is checked
    Then the output mentions "ERROR E-SCHEMA"

  Scenario: An unknown source role fails
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-02","kind":"confirms","of":"S-01","at":"2026-11-01","sources":[{"kind":"slack","ref":"x","role":"maybe"}]}
      ```
    When the log is checked
    Then the output mentions:
      | ERROR E-SCHEMA      |
      | unknown source role |

  Scenario: A record id must start with the name of its story
    Given a project with the header row scenario
    And the log "OTHER" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked
    Then the output mentions:
      | ERROR E-SCHEMA         |
      | must start with OTHER- |

  Scenario: A badly formed scenario id fails and is named
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x","effects":[{"op":"adds","scenario":"Spec_Header","fp":"aaaaaaaa"}]}
      ```
    When the log is checked
    Then the output mentions:
      | ERROR E-SCHEMA |
      | Spec_Header    |

  Scenario: A duplicate record id fails
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked
    Then the output mentions "ERROR E-DUP-ID"

  Scenario: Dangling references are each reported
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-02","kind":"decision","story":"S","at":"2026-11-01","text":"x","supersedes":["S-99"]}
      {"v":1,"id":"S-03","kind":"decision","story":"S","at":"2026-11-01","text":"x","resolves":["S-99"]}
      {"v":1,"id":"S-04","kind":"confirms","of":"S-99","at":"2026-11-01","sources":[]}
      ```
    When the log is checked
    Then the output has 3 lines mentioning "E-REF"

  Scenario: Windows line endings, blank lines and a missing final newline are tolerated
    Given a project with the header row scenario
    And the log "S" is written with Windows line endings, a blank line between the records and no final newline, holding these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
      | S-02 | 2026-11-01 | Dates use one format.   |                                             |
    When the log is checked
    Then the script exits with status 0
    And the output mentions "summary errors=0"

  Scenario: A project with no decisions folder passes and says the log is empty
    Given a project with no scenarios
    And the decisions folder is missing
    When the log is checked
    Then the script exits with status 0
    And the output mentions "I-EMPTY"

  Scenario: An empty log file passes
    Given a project with no scenarios
    And the log "S" is empty
    When the log is checked
    Then the script exits with status 0

  Scenario: Without jq the script says so and exits 2
    When the log is checked without jq
    Then the script exits with status 2
    And the output mentions "jq"

  Scenario: The decisions folder can come from the environment
    Given a project with the header row scenario
    And the log "S" in the folder "custom" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked with only the environment naming the folder "custom"
    Then the script exits with status 0
    And the output does not mention "I-EMPTY"

  Scenario: A flag for the decisions folder wins over the environment
    Given a project with the header row scenario
    And the log "S" in the folder "custom" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    When the log is checked with the environment naming the folder "bogus" and the flag naming the folder "custom"
    Then the output does not mention "I-EMPTY"

  Scenario: With no flag and no environment the default folder is used
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31"}
      ```
    When the log is checked with no folder given
    Then the output mentions "ERROR E-SCHEMA"

  Scenario: An unknown record kind fails and names the kind
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"wish","story":"S","at":"2026-10-31","text":"x"}
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions:
      | ERROR E-SCHEMA    |
      | unknown kind wish |

  Scenario: An unknown source kind fails and names the kind
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-02","kind":"confirms","of":"S-01","at":"2026-11-01","sources":[{"kind":"pigeon","ref":"x","role":"agreed"}]}
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions:
      | ERROR E-SCHEMA      |
      | unknown source kind pigeon |

  Scenario: An effect with a missing key fails and names the key
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"x","effects":[{"op":"adds","scenario":"spec-header-row"}]}
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions "effect adds is missing"

  Scenario: A field that must be a list but is not fails and names the field
    Given a project with the header row scenario
    And the log "S" gets these decisions:
      | id   | at         | text                    | effect                                      |
      | S-01 | 2026-10-31 | Header row is exported. | adds spec-header-row (fingerprint aaaaaaaa) |
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-02","kind":"decision","story":"S","at":"2026-11-01","text":"x","supersedes":"S-01"}
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions:
      | ERROR E-SCHEMA                |
      | supersedes must be a list     |

  Scenario: A dangling reference fails the check
    Given a project with the header row scenario
    And the log "S" gets these lines:
      ```
      {"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-11-01","text":"x","supersedes":["S-99"]}
      ```
    When the log is checked
    Then the script exits with status 1
    And the output mentions "ERROR E-REF"

  Scenario: The project folders of the decision scenarios are gone
    Then no project folder of the decision scenarios of this run is left in the temp folder
