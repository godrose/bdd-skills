@layout
Feature: The plugin lives in its own folder

  The plugin sits in plugin/, so users get only what the directory scans. The manifests,
  the commands, the agents and the config template are inside it. Tests, docs, CI, the
  installer and the evals stay outside it.

  Decision (2026-11-11): The "lib.sh sets PLUGIN" check of the old test is not migrated. Why: it tests the bash helper, not the repo, and the library is deleted at the end of the series.

  Scenario: The plugin manifest is in the plugin folder and the marketplace file stays at the root
    Given the repository
    Then the repo has these files:
      | plugin/.claude-plugin/plugin.json |
      | .claude-plugin/marketplace.json   |

  Scenario: The repo root holds no plugin manifest
    Given the repository
    Then the repo has none of these paths:
      | .claude-plugin/plugin.json |

  Scenario: The marketplace entry points at the plugin folder
    Given the marketplace file
    Then its first plugin has the source "./plugin"

  Scenario: The commands and agents are in the plugin folder, not at the repo root
    Given the repository
    Then the repo has these folders:
      | plugin/commands |
      | plugin/agents   |
    And the repo has none of these paths:
      | commands |
      | agents   |

  Scenario: The config template is in the plugin folder, not at the repo root
    Given the repository
    Then the repo has these files:
      | plugin/bdd-config.template.md |
    And the repo has none of these paths:
      | bdd-config.template.md |

  Scenario: The repo root keeps what users do not install
    Given the repository
    Then the repo has these paths:
      | tests        |
      | docs         |
      | .github      |
      | install.sh   |
      | CLAUDE.md    |
      | CHANGELOG.md |
      | README.md    |
      | LICENSE      |
      | evals        |
      | scripts      |
      | schemas      |

  Scenario: The plugin folder holds none of what users do not install
    Given the repository
    Then the repo has none of these paths:
      | plugin/tests        |
      | plugin/docs         |
      | plugin/.github      |
      | plugin/install.sh   |
      | plugin/CLAUDE.md    |
      | plugin/CHANGELOG.md |
      | plugin/evals        |
      | plugin/scripts      |
      | plugin/schemas      |
