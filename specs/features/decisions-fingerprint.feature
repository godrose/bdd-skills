@decisions
Feature: Finding a scenario and its fingerprint

  The script finds a scenario by its id tag and gives a fingerprint of what it says. A changed meaning changes the fingerprint. A changed tag, comment or spacing does not.

  Decision (2026-11-11): The fixes made after the first review, a tagged examples block and a tag inside a docstring, are kept here. Why: they are about tags and fingerprints.

  Scenario: A plain scenario has a fingerprint of 8 characters
    Given a project with the header row scenario
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 0
    And the output is 8 characters long

  Scenario: Other tags, comments, spacing, blank lines and Windows line endings do not change the fingerprint
    Given a project with the header row scenario
    And the fingerprint of "spec-header-row" is remembered
    And the feature file "export.feature" reads, with Windows line endings:
      ```
      # top comment
      Feature: Export
        @spec-header-row @other-tag @pending
        # between tags and keyword
        Scenario:    Header   row
              Given an order list
          When I export it

          Then the file has a header row
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the output is the remembered fingerprint

  Scenario: Flipping a status tag does not change the fingerprint
    Given a project with the header row scenario
    And the fingerprint of "spec-header-row" is remembered
    And the text " @pending" is replaced by "" in the feature file "export.feature"
    When the fingerprint of "spec-header-row" is asked for
    Then the output is the remembered fingerprint

  Scenario: Rewording a step changes the fingerprint
    Given a project with the header row scenario
    And the fingerprint of "spec-header-row" is remembered
    And the text "When I export it" is replaced by "When I export the list" in the feature file "export.feature"
    When the fingerprint of "spec-header-row" is asked for
    Then the output is not the remembered fingerprint

  Scenario: A scenario outline has a fingerprint
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        @spec-header-row
        Scenario Outline: Header row
          Given an order list with <count> orders
          Then the file has a header row

          Examples:
            | count |
            | 0     |
            | 5     |
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 0

  Scenario: Changing a cell in the examples changes the fingerprint
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        @spec-header-row
        Scenario Outline: Header row
          Given an order list with <count> orders
          Then the file has a header row

          Examples:
            | count |
            | 0     |
            | 5     |
      ```
    And the fingerprint of "spec-header-row" is remembered
    And the text "| 5 " is replaced by "| 6 " in the feature file "a.feature"
    When the fingerprint of "spec-header-row" is asked for
    Then the output is not the remembered fingerprint

  Scenario: An id in a comment is not a tag
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        # @spec-header-row
        Scenario: Header row
          Given an order list
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 1
    And the output mentions "not found"

  Scenario: An id inside a step is not a tag
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        Scenario: Header row
          Given a note says @spec-header-row
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 1

  Scenario: An id on the Feature line is not a scenario tag
    Given the feature file "a.feature" reads:
      ```
      @spec-header-row
      Feature: Export
        Scenario: Header row
          Given an order list
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 1

  Scenario: A duplicate id in one file is ambiguous
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
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 1
    And the output mentions "ambiguous"

  Scenario: A duplicate id across files fails
    Given a project with the header row scenario
    And the feature file "export.feature" is copied to "b.feature"
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 1

  Scenario: Two ids on one scenario share a fingerprint
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        @spec-one @spec-two
        Scenario: Both
          Given a
      ```
    And the fingerprint of "spec-one" is remembered
    When the fingerprint of "spec-two" is asked for
    Then the output is the remembered fingerprint

  Scenario: A feature file with no final newline works
    Given the feature file "a.feature" reads, with no final newline:
      ```
      Feature: Export
        @spec-header-row
        Scenario: Header row
          Given an order list
      ```
    When the fingerprint of "spec-header-row" is asked for
    Then the script exits with status 0

  Scenario: A change in a neighbouring scenario does not move the fingerprint
    Given the feature file "a.feature" reads:
      ```
      Feature: Export
        Rule: Headers
          @spec-header-row
          Scenario: Header row
            Given an order list

          @spec-other
          Scenario: Other
            Given one
      ```
    And the fingerprint of "spec-header-row" is remembered
    And the text "Given one" is replaced by "Given two" in the feature file "a.feature"
    When the fingerprint of "spec-header-row" is asked for
    Then the output is the remembered fingerprint

  Scenario: Without a features folder the script exits 2
    Given a project with no scenarios
    When the fingerprint of "spec-header-row" is asked for without a features folder
    Then the script exits with status 2

  Scenario: A tagged examples block counts in the fingerprint and does not hide the next scenario
    Given the feature file "a.feature" reads:
      ```
      Feature: A
        @spec-out
        Scenario Outline: O
          Given <x>
          @smoke
          Examples:
            | x |
            | 1 |

        @spec-next
        Scenario: N
          Given n
      ```
    And the fingerprint of "spec-out" is remembered
    And the text "| 1 |" is replaced by "| 2 |" in the feature file "a.feature"
    When the fingerprint of "spec-out" is asked for
    Then the output is not the remembered fingerprint
    And the fingerprint of "spec-next" can be found

  Rule: A scenario with a docstring that holds tag and scenario lines

    Background:
      Given the feature file "a.feature" reads:
        ```
        Feature: A
          @spec-doc
          Scenario: D
            Given text:
              """
              @spec-fake
              Scenario: not real
              """
            Then ok
        ```

    Scenario: A tag inside a docstring is not a scenario tag
      When the fingerprint of "spec-fake" is asked for
      Then the script exits with status 1

    Scenario: The text of a docstring belongs to the fingerprint of its scenario
      Given the fingerprint of "spec-doc" is remembered
      And the text "not real" is replaced by "still not real" in the feature file "a.feature"
      When the fingerprint of "spec-doc" is asked for
      Then the output is not the remembered fingerprint

    Scenario: The check ignores the tag inside the docstring and counts no legacy scenario
      When the log is checked
      Then the output does not mention "spec-fake"
      And the output does not mention "I-LEGACY"
