@readme
Feature: The README puts the way in first and the reference later

  Decision (2026-11-11): The order checks that sat all through the old file are gathered here. Why: a maintainer who moves a section looks in one place.
  Decision (2026-11-11): An item counts at the first line that holds its text, anywhere in the file. Why: that is what the old file did.

  Scenario: The README has the sections of the way in and the reference
    Given the README
    Then it contains:
      | ## Contents     |
      | ## Quick start  |
      | ## The flow     |
      | ## Modes        |
      | ## Install      |
      | ## Configure    |
      | ## Decision log |
      | ## Update       |

  Scenario: Contents, Quick start and The flow come in that order
    Given the README
    Then it mentions these in this order:
      | ## Contents    |
      | ## Quick start |
      | ## The flow    |

  Scenario: The install line, /bdd:init and /bdd:discover come before The flow
    Given the README
    Then each of these comes before "## The flow":
      | /plugin marketplace add godrose/bdd-skills |
      | /bdd:init                                  |
      | /bdd:discover <story>                      |

  Scenario: The flow comes before Install, What's included and Update
    Given the README
    Then it mentions these in this order:
      | ## The flow        |
      | ## Install         |
      | ## What's included |
      | ## Update          |

  Scenario: Update comes before Related projects, Contributing and License
    Given the README
    Then it mentions these in this order:
      | ## Update           |
      | ## Related projects |
      | ## Contributing     |
      | ## License          |
