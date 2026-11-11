@deliver-text
Feature: The deliver command reports parked stops as risks in plain words

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command is for a person with or without a developer
    Given the plugin command "deliver"
    Then it contains "with or without a developer or architect watching"

  Scenario: Parked stops become risks in plain words
    Given the plugin command "deliver"
    Then it contains:
      | Not checked, and what it risks:                                          |
      | one plain sentence on what could go wrong for the users                  |
      | on a "For the developer" line                                            |
      | Never name a file, a field, a function or a status in the plain sentence |
      | Do not ask whether there is a developer                                  |
      | is never reported as passed                                              |

  Scenario: With nothing parked the section is left out
    Given the plugin command "deliver"
    Then it contains:
      | Leave the "Not checked, and what it risks" section out entirely when nothing was parked                                                        |
      | Leave the "Not checked, and what it risks" section out entirely when nothing was parked: no heading, and no line that says nothing was parked |

  Scenario: The risk section comes before the developer note
    Given the plugin command "deliver"
    Then it mentions these in this order:
      | Not checked, and what it risks: |
      | Developer note: <               |
    And it does not contain "Developer note: <parked technical stops"

  Scenario: The no-developer pack records its decisions
    Given the file "docs/discovery/2026-11-11-deliver-no-developer.md"
    Then it contains "Decisions"
