@flow-discover
Feature: A discover run saves every message and says whether it finished

  Decision (2026-11-11): The discover harness is played with the same fake claude as the deliver harness. Why: the old file did, and it needs no login and no network.
  Decision (2026-11-11): The product manager reply in a discover run is "A. reply N" for every turn. Why: the old file scripted it that way. Deliver replies "Approved" to the first two.

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: The first assistant message is saved
    Given the assistant says:
      """
      What exists: nothing. Q one?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the file "turn-01-assistant.txt" of the run reads "What exists: nothing. Q one?"

  Scenario: The first reply is saved
    Given the assistant says:
      """
      What exists: nothing. Q one?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the file "turn-01-pm.txt" of the run reads "A. reply 1"

  Scenario: The second message is saved in turn order
    Given the assistant says:
      """
      What exists: nothing. Q one?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the run folder has:
      | turn-02-assistant.txt |

  Scenario: A readiness line ends the run
    Given the assistant says:
      """
      What exists: nothing. Q one?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the file "meta.json" of the run contains:
      | "finished": true |
      | "turns": 2       |

  Scenario: No readiness line stops the run at the turn cap
    Given the assistant says:
      """
      What exists: x. One?
      """
    And the assistant says:
      """
      More?
      """
    And the assistant says:
      """
      Again?
      """
    And the assistant says:
      """
      Again2?
      """
    And the harness is limited to 3 turns
    When the harness plays the conversation
    Then the file "meta.json" of the run contains:
      | "finished": false |
      | "turns": 3        |

  Scenario: A run that hit the cap says it did not finish
    Given the assistant says:
      """
      What exists: x. One?
      """
    And the assistant says:
      """
      More?
      """
    And the assistant says:
      """
      Again?
      """
    And the assistant says:
      """
      Again2?
      """
    And the harness is limited to 3 turns
    When the harness plays the conversation
    Then the report of the harness contains "did not finish"

  Scenario: The persona card is passed to the small model
    Given the assistant says:
      """
      What exists: x. One?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the first prompt to the product manager model contains the first line of the persona card of the fixture

  Scenario: The reply of the small model is the next prompt
    Given the assistant says:
      """
      What exists: x. One?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then call 2 to the assistant contains:
      | A. reply 1 |

  Scenario: A relative output folder works
    Given the assistant says:
      """
      What exists: x. One?
      """
    And the assistant ends with an unfinished readiness block
    And the output folder is given as a relative path
    When the harness plays the conversation
    Then the run folder has:
      | turn-01-assistant.txt |

  Scenario: A run that got no answer says so
    Given the assistant gives no answer
    When the harness plays the conversation
    Then the report of the harness contains "no answer"

  Scenario: A run that got no answer is not scored
    Given the assistant gives no answer
    When the harness plays the conversation
    Then the report of the harness does not contain "0 of"
