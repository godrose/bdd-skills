@readme @glossary
Feature: The Glossary groups its words by layer and defines each word once

  Decision (2026-11-13): The Glossary has four groups: BDD, This plugin, Decision log (opt-in) and Claude Code. Why: the flat list mixed BDD practice, plugin artifacts, commands, decision-log internals and platform words, and a reader could not tell which layer a word belonged to.
  Decision (2026-11-13): The command and agent entries (Verifier, Triage, Reconcile) are gone. Why: they are described in The flow, Decision log and Architecture, and a second definition can drift from those. This replaces the glossary of 2026-11-13 (#96).
  Decision (2026-11-13): Every word defined is used elsewhere in the README. Why: an entry nobody uses is dead text.

  Scenario: The Glossary has four groups in order
    Given the README
    Then it mentions these in this order:
      | ## Glossary                |
      | ### BDD                    |
      | ### This plugin            |
      | ### Decision log (opt-in)  |
      | ### Claude Code            |
      | ## Related projects        |

  Scenario: Each group holds its own words
    Given the README
    Then it has a section "### BDD" holding:
      | **Acceptance criteria** |
      | **Red-first**           |
    And it has a section "### This plugin" holding:
      | **Discovery pack**  |
      | **Reuse audit**     |
      | **Skill role**      |
      | **Specify-only**    |
      | **Pending and manual-only tags** |
    And it has a section "### Decision log (opt-in)" holding:
      | **Decision log** |
      | **Drift**        |
      | **Orphan**       |
      | **Undecided**    |
      | **Conflict**     |
    And it has a section "### Claude Code" holding:
      | **Marketplace**  |
      | **Headless run** |

  Scenario: The command and agent entries are gone
    Given the README
    Then it has a section "## Glossary" lacking:
      | **Verifier** |
      | **Triage**   |
      | **Reconcile** |

  Scenario: Every word defined in the Glossary is used elsewhere in the README
    Given the README
    Then every term defined in the Glossary is used elsewhere in it
