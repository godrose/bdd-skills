@skills-text
Feature: The discover command has its seven sections

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario Outline: The discover command has the heading <heading>
    Given the plugin command "discover"
    Then it contains "## <heading>"

    Examples:
      | heading                |
      | Story                  |
      | Open questions         |
      | Candidate examples     |
      | Edge and negative cases |
      | Vocabulary check       |
      | Candidate exclusions   |
      | Readiness              |
