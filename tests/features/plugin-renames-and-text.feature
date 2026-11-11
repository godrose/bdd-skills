@plugin-text
Feature: Feedback became triage, design shows every scenario and discover looks for existing behavior

  These scenarios read the text of the commands and of the config template. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): That triage.md exists and the feedback-intake row are written once here. Why: test_skills.sh keeps only a weaker substring check, which skips them later.

  Scenario: Feedback was renamed to triage
    Given the repository
    Then the repo has these files:
      | plugin/commands/triage.md |
    And the repo has none of these paths:
      | plugin/commands/feedback.md |
    Given the plugin command "triage"
    Then it contains "## BDD Triage"
    And it does not contain "## BDD Feedback"

  Scenario: The template names triage as the feedback-intake skill
    Given the file "plugin/bdd-config.template.md"
    Then it contains "| feedback-intake | `bdd:triage`"

  Scenario: Design shows every scenario in full before approval
    Given the plugin command "design"
    Then it contains:
      | Write every scenario out in full       |
      | Do not abbreviate                      |
      | Abbreviating scenarios in the proposal |

  Scenario: Discover looks for existing behavior in the code
    Given the plugin command "discover"
    Then it contains:
      | Look for existing behavior                 |
      | unit tests                                 |
      | from code                                  |
      | acceptance scenarios for existing behavior |
