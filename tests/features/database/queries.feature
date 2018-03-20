Feature: Smart Queries
In order to effictively visit users based on a scheduled strategy
I want to make sure the queries only return intended results

@followup
Scenario: Followup query returns accurate data
Given I execute a followup_query
When I query each result for additional info
Then Each result should obey config file rules

@followup
Scenario: Followup query result follows last_visit rules
Given I execute a followup_query
When I evaluate the first query result
Then the last_visit date should be older than "2" days

@new_user
Scenario: New user query only returns new users
Given I execute a new_user_query
When I evaluate the results
Then No results should contain a count or last_visit value greater than 0

@ignore_list
Scenario: Followup query obeys ignore list
Given I execute a followup_query
When I evaluate the results
Then There should not be any values of ignore_list = 0
