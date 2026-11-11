@flow-discover
Feature: The harness needs claude, and the installer does not carry it

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: No claude stops the harness
    Given no claude is on the path
    When the harness plays the conversation
    Then the run fails

  Scenario: No claude is said in the output
    Given no claude is on the path
    When the harness plays the conversation
    Then the output mentions "claude"

  Scenario: No claude writes nothing
    Given no claude is on the path
    When the harness plays the conversation
    Then no output folder was written

  Scenario: The installer does not mention flows
    Given the file "install.sh"
    Then it does not contain "flows"
