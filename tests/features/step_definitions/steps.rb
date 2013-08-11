# require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "includes.rb"))
require_relative '../../../lib/LazyCupid/includes'

Before do
  @account = "***REMOVED***"
  @password = "***REMOVED***"
  url = "http://www.okcupid.com/profile/***REMOVED***"
  @settings = LazyCupid::Settings.new(username: @account, path: File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config")))
  @db = LazyCupid::DatabaseMgr.new(login_name: @account, settings: @settings)
  @profile  = LazyCupid::Users.new(database: @db)
  @db.delete_user("fake_user")
  @browser = LazyCupid::Browser.new(username: @account, password: @password, log: @log)
  @browser.login
  request_id = Time.now.to_i
  @browser.request(url, request_id)
  until @browser.hash[request_id][:ready]
    sleep 0.1
  end
  @page = @browser.hash[request_id]
  @html = @page[:html]
  @body = @page[:body]
end

Given(/^Username "(.*?)" is not in the database$/) do |user|
  puts @db.existsCheck(user)
  @db.existsCheck(user) == false
end

When(/^I add user "(.*?)" to the database$/) do |arg1|
  @db.add_user(arg1, "F", "cucumber")
end

Then(/^The user exists check should return "(.*?)"$/) do |arg1|
  @db.existsCheck("fake") == arg1.to_s
end

Given(/^Username "(.*?)" exists$/) do |arg1|
  @db.existsCheck(arg1) == true
end

When(/^I execute the delete_user method on "(.*?)"$/) do |arg1|
  @db.delete_user(arg1)
end

Then(/^the user exists check should return "(.*?)"$/) do |arg1|
  @db.existsCheck(arg1) == arg1
end

When(/^I execute the ignore_user method on "(.*?)"$/) do |arg1|
  @db.ignore_user(arg1)
end

Then(/^is_ignored check on "(.*?)" should return true$/) do |arg1|
  @db.is_ignored(arg1) == true
end

Given(/^I execute a followup_query$/) do
  @result = @db.followup_query
end

When(/^I query each result for additional info$/) do
  @result.first
end

Then(/^Each result should obey config file rules$/) do
  @valid_date = Time.now.to_i - (86400 * 2)
  truth = false
  @result.each do |result|
    if result["last_visit"].to_i >= @valid_date
      truth = true
    end
  end
  truth
end

When(/^I evaluate the first query result$/) do
  @hash = Hash.new
  @users = Hash.new
  @result.each do |item|
    @hash[item["name"]] = item
  end

  @users[user.shift] = user.shift

  # p @hash
end

Then(/^the last_visit date should be older than "(.*?)" days$/) do |days|
  @valid_date = Time.now.to_i - (86400 * days.to_i)
  p Chronic.parse("#{@valid_date} days ago")
  @first["last_visit"].to_i >= @valid_date
end

Given(/^I execute a new_user_query$/) do
  @result = @db.new_user_smart_query
end

Then(/^No results should contain a count or last_visit value greater than (\d+)$/) do |arg1|
  @bad = 0
  @hash.each do |user|
    # p user
    unless (user[1]["counts"].to_i == nil || user[1]["counts"] == 0) && user[1]["last_visit"].to_i == nil
      @bad += 1
    end
  end
  @bad == 0
end


When(/^I evaluate the results$/) do
  @hash = Hash.new
  # @result.each do |item|
  #   @hash[item["name"]] = item
  # end
  @hash = Hash[@result.map { |r| [r["name"], r] }]
  # puts @hash
end

Then(/^There should not be any values of ignore_list = (\d+)$/) do |arg1|
  @bad = 0
  @users = Hash.new
  @hash.each do |user|
    # p user
    unless user[1]["ignore_list"].to_i == 0
      @bad += 1
    end
  end
  @bad == 0
end

Given(/^I load a sample profile$/) do
  puts "Sample profile loaded"
end

When(/^I isolate the username field$/) do
  @result = @profile.profile(@page)[:handle]
end

Then(/^The parser should return a username string$/) do
  puts @result
  @result == "---Nick"
end

When(/^I isolate the match percent field$/) do
  @result = @profile.profile(@page)[:match_percentage]
end

Then(/^The parser should return a match percent string$/) do
  puts @result
end

When(/^I isolate the age field$/) do
  @result = @profile.profile(@page)[:age]
end

Then(/^The parser should return a age string$/) do
  p @result
  puts @result == 27
end

When(/^I isolate the height field$/) do
  @result = @profile.profile(@page)[:height]
end

Then(/^The parser should return a height string$/) do
  puts @result
end

When(/^I isolate the smoking field$/) do
  @result = @profile.profile(@page)[:smoking]
end

Then(/^The parser should return a smoking string$/) do
  puts @result
end

When(/^I isolate the drinking field$/) do
  @result = @profile.profile(@page)[:drinking]
end

Then(/^The parser should return a drinking string$/) do
  puts @result
end

When(/^I isolate the location field$/) do
  @result = @profile.profile(@page)[:city]
end

Then(/^The parser should return a location string$/) do
  puts @result
end

When(/^I isolate the orientation field$/) do
  @result = @profile.profile(@page)[:sexuality]
end


Then(/^The parser should return a orientation string$/) do
  puts @result
end

When(/^I isolate the gender field$/) do
  @result = @profile.profile(@page)[:gender]
end

Then(/^The parser should return a gender string$/) do
  puts @result
end

When(/^I isolate the status field$/) do
  @result = @profile.profile(@page)[:relationship_status]
end

Then(/^The parser should return a status string$/) do
  puts @result
end

When(/^I isolate the friend_percent field$/) do
  @result = @profile.profile(@page)[:friend_percentage]
end

Then(/^The parser should return a friend_percent string$/) do
  puts @result
end

When(/^I isolate the enemy_percent field$/) do
  @result = @profile.profile(@page)[:enemy_percentage]
end

Then(/^The parser should return a enemy_percent string$/) do
  puts @result
end

When(/^I isolate the ethnicity field$/) do
  @result = @profile.profile(@page)[:ethnicity]
end

Then(/^The parser should return a ethnicity string$/) do
  puts @result
end

When(/^I isolate the kids field$/) do
  @result = @profile.profile(@page)[:kids]
end

Then(/^The parser should return something$/) do
  puts @result
end

When(/^I isolate the drugs field$/) do
  @result = @profile.profile(@page)[:drugs]
end

When(/^I isolate the last_online field$/) do
  @result = @profile.profile(@page)[:last_online]
end

When(/^I isolate the relative_distance field$/) do
  @result = @profile.profile(@page)[:distance]
end
