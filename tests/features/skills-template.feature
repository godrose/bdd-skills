@skills-text
Feature: The config template has the rows the commands read

  These scenarios read the config template. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The prepare and step_batch rows are checked as the text "| <row> | `` (optional", without the line-start anchor. Why: the row starts with a pipe, so a match inside a line needs an earlier pipe cell, and no step matches the start of a line.
  Decision (2026-11-12): The unautomated_tag key is checked once, through its @pending row. Why: the row check implies the key.

  Scenario: The template has the workflow and discovery rows
    Given the file "plugin/bdd-config.template.md"
    Then it contains:
      | workflow_mode |
      | glossary_file |
      | discovery_dir |
      | discoverer    |
    And it contains "| lint |"

  Scenario: The unautomated tag is @pending and the automated tag has a row
    Given the file "plugin/bdd-config.template.md"
    Then it contains:
      | automated_tag |
    And it contains "| unautomated_tag | `@pending`"
    And it does not contain "| unautomated_tag | `@manual`"

  Scenario: The template has the decision log and reconciler rows
    Given the file "plugin/bdd-config.template.md"
    Then it contains:
      | decisions_dir      |
      | scenario_id_prefix |
      | status_scope       |
      | manual_only_tag    |
      | blocked_tag        |
      | planned_dir        |
      | manual_only_dir    |
      | decision_log       |
      | reconciler         |

  Scenario: The template has the out-of-scope row
    Given the file "plugin/bdd-config.template.md"
    Then it contains "| out_of_scope_file | `docs/out-of-scope.md`"

  Scenario Outline: The <row> row is empty with an optional note
    Given the file "plugin/bdd-config.template.md"
    Then it contains "| <row> | `` (optional"

    Examples:
      | row        |
      | prepare    |
      | step_batch |

  Scenario: The generate row may be empty, and steps_dir takes a list
    Given the file "plugin/bdd-config.template.md"
    Then it contains:
      | empty if the framework reads .feature files directly |
      | comma-separated                                      |

  Scenario: The template has no row for required_tags, adapters_dir or domain_dir
    Given the file "plugin/bdd-config.template.md"
    Then it does not contain:
      | required_tags |
      | adapters_dir  |
      | domain_dir    |
