@readme
Feature: The README opens with a hero block

  Decision (2026-11-11): Headings stay plain ASCII and the README has no em-dash. Why: the old file held both, and the style guide asks for it.

  Scenario: The README opens with a centered block, a banner, a tagline and three badges
    Given the README
    Then it contains:
      | <div align="center">                                |
      | <pre>                                               |
      | </pre>                                              |
      | **🥒 Agree the examples first, then automate them** |
      | actions/workflows/ci.yml/badge.svg                  |
      | img.shields.io/badge/license-Apache--2.0            |
      | img.shields.io/github/stars/godrose/bdd-skills      |

  Scenario: The README has three tips
    Given the README
    Then it contains:
      | > 💡 **Tip:**            |
      | > 🧪 **Trivial change?** |
      | > 🔒 **Never deletes:**  |

  Scenario: The demo GIF exists and the README shows it
    Given the repository
    Then the repo has these files:
      | docs/demo/story.gif |
    Given the README
    Then it contains:
      | <img src="docs/demo/story.gif" |

  Scenario: The centered block and the demo GIF come before Contents
    Given the README
    Then each of these comes before "## Contents":
      | <div align="center"> |
      | docs/demo/story.gif  |

  Scenario: The README names three related projects with their links
    Given the README
    Then it contains:
      | ## Related projects                                          |
      | [Playwright-BDD](https://github.com/vitalets/playwright-bdd) |
      | [Cucumber](https://github.com/cucumber/cucumber-js)          |
      | [Reqnroll](https://github.com/reqnroll/Reqnroll)             |

  Scenario: No heading in the README has a non-ASCII character
    Given the README
    Then it has no heading with a non-ASCII character

  Scenario: The README has no em-dash
    Given the README
    Then it has no em-dash
