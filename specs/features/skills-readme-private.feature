@skills-text
Feature: The README says the repository is private for now

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The README says who can install and which route needs a public repository
    Given the README
    Then it contains:
      | The repository is private for now        |
      | read access                              |
      | gh auth setup-git                        |
      | ssh-agent                                |
      | only works once the repository is public |
