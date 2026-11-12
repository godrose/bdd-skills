@readme
Feature: The README says how to contribute and under what licence

  Scenario: The README has Contributing and License sections
    Given the README
    Then it contains:
      | ## Contributing |
      | ## License      |

  Scenario: The README tells contributors to run the suite, write discovery packs and where to start
    Given the README
    Then it contains:
      | bash tests/run.sh |
      | docs/discovery/   |
      | good first issue  |

  Scenario: The README names the licence
    Given the README
    Then it contains "Apache License 2.0"

  Scenario: The README ends with the copyright line
    Given the README
    Then its last non-empty line is "Copyright 2026 Gennady Verdel"

  Scenario: The licence has the copyright line filled in
    Given the file "LICENSE"
    Then it contains "Copyright 2026 Gennady Verdel"
    And it does not contain "[yyyy]"
    And it does not contain "[name of copyright owner]"
