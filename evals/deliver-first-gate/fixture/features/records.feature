Feature: Records export
  Records can be exported to a CSV file from the records page.

  Scenario: Export all records
    Given the records page lists 3 records
    When I export the records to CSV
    Then the CSV has 3 rows and a header row
