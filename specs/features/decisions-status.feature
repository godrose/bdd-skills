@decisions
Feature: The status of a scenario

  The status says whether a scenario is planned, automated, manual-only or blocked. It is read from tags, or from the Feature tags or the folder, depending on the scope.

  Decision (2026-11-11): Each status rule is its own scenario, not an outline. Why: the options differ in kind, not only in value.

  Scenario: A pending tag means planned
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @pending
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "planned"

  Scenario: No marker means automated
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "automated"

  Scenario: A manual-only tag means manual-only
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @manual-only
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "manual-only"

  Scenario: Manual-only wins over pending
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @pending @manual-only
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "manual-only"

  Scenario: A blocked tag means blocked when the blocked tag is given
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @blocked
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for with the options "--blocked-tag @blocked"
    Then the output is exactly "blocked"

  Scenario: A blocked tag is ignored when the blocked tag is not given
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @blocked
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "automated"

  Scenario: A custom planned tag works
    Given the feature file "s.feature" reads:
      ```
      Feature: F
        @spec-x @manual
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for with the options "--planned-tag @manual"
    Then the output is exactly "planned"

  Scenario: With feature scope the tags of the Feature count
    Given the feature file "s.feature" reads:
      ```
      @pending
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for with the options "--scope feature"
    Then the output is exactly "planned"

  Scenario: With scenario scope the tags of the Feature are ignored
    Given the feature file "s.feature" reads:
      ```
      @pending
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for
    Then the output is exactly "automated"

  Scenario: With directory scope a scenario in the planned folder is planned
    Given the feature file "formulated/s.feature" reads:
      ```
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for with the options "--scope directory --planned-dir formulated"
    Then the output is exactly "planned"

  Scenario: With directory scope a scenario in a nested manual-only folder is manual-only
    Given the feature file "manual/ldap/s.feature" reads:
      ```
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-x" is asked for with the options "--scope directory --manual-only-dir manual"
    Then the output is exactly "manual-only"

  Scenario: A scenario that does not exist exits 1
    Given the feature file "manual/ldap/s.feature" reads:
      ```
      Feature: F
        @spec-x
        Scenario: X
          Given x
      ```
    When the status of "spec-nope" is asked for
    Then the script exits with status 1
    And the output mentions "not found"
