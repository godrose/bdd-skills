@skills-text
Feature: The design command reads the config rows and stops without a config

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): size gate and unautomated_tag are each checked once. Why: a duplicate adds no check.

  Scenario: The command reads the decision and tag rows
    Given the plugin command "design"
    Then it contains:
      | manual_only_tag        |
      | status_scope           |
      | decision_log           |
      | decisions.sh fingerprint |
      | scenario_id_prefix     |
      | size gate              |
      | Decisions              |
      | decisions.sh check     |

  Scenario: The command reads the manual-only folder and its default
    Given the plugin command "design"
    Then it contains:
      | manual_only_dir   |
      | default `scenario` |

  Scenario: The command does not default to the manual tag
    Given the plugin command "design"
    Then it does not contain "default `@manual`"

  Scenario: A missing config stops the command
    Given the plugin command "design"
    Then it contains:
      | does not exist, say so and stop |
      | `bdd-config.template.md`        |

  Scenario: The steps folder takes several paths
    Given the plugin command "design"
    Then it contains "comma-separated"
