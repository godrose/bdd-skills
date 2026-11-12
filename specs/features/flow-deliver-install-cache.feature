@flow-deliver
Feature: The harness installs the test runner once, into a cache keyed on the lockfile

  Decision (2026-11-11): The fake npm stands in for the install. Why: no network, and the old file did the same.

  Scenario: The runner is installed once for the first run
    Given an empty cache for the installed runner
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the runner was installed 1 time

  Scenario: The cache is keyed on the lockfile
    Given an empty cache for the installed runner
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the cache holds the runner under the first 16 characters of the hash of the lockfile

  Scenario: The runner is copied into the project of the run
    Given an empty cache for the installed runner
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the project of the run has the runner

  Scenario: The same lockfile is not installed again
    Given an empty cache for the installed runner
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the conversation has been played once
    When the harness plays the conversation
    Then the runner was installed 1 time

  Scenario: A changed lockfile is a new cache
    Given an empty cache for the installed runner
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the conversation has been played once
    And the lockfile of the fixture is changed in a copy of the harness
    When the harness of the copy plays the conversation
    Then the runner was installed 2 times

  Scenario: An install that fails stops the harness and says why
    Given an empty cache for the installed runner
    And the install of the runner fails
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the run fails
    And the output mentions "install"

  Scenario: An install that fails starts no session
    Given an empty cache for the installed runner
    And the install of the runner fails
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then no session was started

  Scenario: An install that fails leaves no cache behind
    Given an empty cache for the installed runner
    And the install of the runner fails
    And the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the cache holds nothing

  Scenario: The cache is kept under the results folder by default
    Given the file "flows/run.sh"
    Then it contains "results/cache"
