@flow-discover
Feature: The discover fixtures are a project with one scenario and a project with none

  Decision (2026-11-11): The fixture checks run as they are on the repo files, with the Windows line-endings case played through the harness. Why: the old file did the same.

  Scenario: Fixture a has one feature file
    Then fixture "a" holds 1 feature file

  Scenario: Fixture a has one scenario
    Given the feature files of fixture "a"
    Then they hold 1 scenario

  Scenario: Fixture b has no feature files and no screens
    Then fixture "b" holds no feature files and no screens

  Scenario: Each fixture has a story
    Then these files exist:
      | flows/fixtures/a/story.txt |
      | flows/fixtures/b/story.txt |

  Scenario: The personas exist
    Then these files exist:
      | flows/personas/founder.md |
      | flows/personas/pm.md      |

  Scenario: Fixture text files with Windows line endings still work
    Given the harness runs discover on fixture "a"
    And the fixture text files of a copy of the harness have Windows line endings
    And the assistant says:
      """
      What exists: x. One?
      """
    And the assistant ends with an unfinished readiness block
    When the harness of the copy plays the conversation
    Then the run folder has:
      | turn-01-assistant.txt |
