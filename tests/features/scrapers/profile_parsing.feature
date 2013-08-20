Feature: Scrape user data from profile page
In order to store accurate user data in the database
As a lazy online dater
I want to be able to pull specific details from each profile I visit

@scraper @alist
Scenario: Username
Given I load a sample profile
When I isolate the username field
Then The parser should return a username string

@scraper @percents
Scenario: Match Percent
Given I load a sample profile
When I isolate the match percent field
Then The parser should return a match percent string

@scraper
Scenario: Age
Given I load a sample profile
When I isolate the age field
Then The parser should return a age string

@scraper
Scenario: Height
Given I load a sample profile
When I isolate the height field
Then The parser should return a height string

@scraper
Scenario: Smoking
Given I load a sample profile
When I isolate the smoking field
Then The parser should return a smoking string

@scraper
Scenario: Drinking
Given I load a sample profile
When I isolate the drinking field
Then The parser should return a drinking string

@scraper
Scenario: Location
Given I load a sample profile
When I isolate the location field
Then The parser should return a location string

@scraper
Scenario: Orientation
Given I load a sample profile
When I isolate the orientation field
Then The parser should return a orientation string

@scraper
Scenario: Gender
Given I load a sample profile
When I isolate the gender field
Then The parser should return a gender string

@scraper
Scenario: Relationship Status
Given I load a sample profile
When I isolate the status field
Then The parser should return a status string

@scraper @percents
Scenario: Friend percent
Given I load a sample profile
When I isolate the friend_percent field
Then The parser should return a friend_percent string

@scraper @percents
Scenario: Enemy percent
Given I load a sample profile
When I isolate the enemy_percent field
Then The parser should return a enemy_percent string

@scraper
Scenario: Ethnicity
When I isolate the ethnicity field
Then The parser should return a ethnicity string

@scraper
Scenario: Kids
When I isolate the kids field
Then The parser should return something

@scraper
Scenario: Drugs
When I isolate the drugs field
Then The parser should return something

@scraper
Scenario: Last online
When I isolate the last_online field
Then The parser should return something

@scraper
Scenario: Relative distance
When I isolate the relative_distance field
Then The parser should return something

@scraper @alist
Scenario: Intended handle
When I isolate the intended_handle field
Then The parser should return something

@scraper
Scenario: Inactive
When I isolate the inactive field
Then The parser should return something

@scraper @alist
Scenario: A list name change
When I isolate the a_list_name_change field
Then The parser should return something

