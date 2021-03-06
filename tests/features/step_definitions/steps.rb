# require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "includes.rb"))
require_relative '../../../lib/LazyCupid/includes'
require_relative 'lib/LazyCupid/database_manager'
require_relative 'lib/LazyCupid/settings'
config_path = File.expand_path("../../config/", __FILE__)
@config       = LazyCupid::Settings.new(username: "***REMOVED***", path: config_path)
@db           = LazyCupid::DatabaseMgr.new(login_name: "***REMOVED***", settings: @config)
# [fix] - login session for tests seems broken
# [fix] - get scraper tests to pass

Before('login') do
  user = "***REMOVED***"
  @account = "----ryan"
  @password = "666yoshi"
  url = "http://www.okcupid.com/profile/#{user}"
  @settings = LazyCupid::Settings.new(username: @account, path: File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config")))
  # @profile  = LazyCupid::Users.new(database: @db)
end

Before('scraper') do
  user = "***REMOVED***"
  @account = "----ryan"
  @password = "666yoshi"
  url = "http://www.okcupid.com/profile/#{user}"
  @settings = LazyCupid::Settings.new(username: @account, path: File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config")))
  @db = LazyCupid::DatabaseMgr.new(login_name: @account, settings: @settings)
  # @profile  = LazyCupid::Users.new(database: @db)
  # @db.delete_user("fake_user")
  @browser = LazyCupid::Browser.new(username: @account, password: @password, log: @log)
  # puts "New login session"
  @browser.login
  request_id = Time.now.to_i
  @browser.send_request(url, request_id)
  until @browser.get_request(request_id)[:ready] == true
    sleep 0.1
  end
  @page = @browser.get_request(request_id)
  @html = @page[:source]
  @body = @page[:body]
  # @browser.go_to("http://www.okcupid.com/logout")
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
  @result = LazyCupid::Profile.parse(@page)[:handle]
end

Then(/^The parser should return a username string$/) do
  puts @result
  @result == "---Nick"
end

When(/^I isolate the match percent field$/) do
  @result = LazyCupid::Profile.parse(@page)[:match_percentage]
end

Then(/^The parser should return a match percent string$/) do
  puts @result
end

When(/^I isolate the age field$/) do
  @result = LazyCupid::Profile.parse(@page)[:age]
end

Then(/^The parser should return a age string$/) do
  p @result
  puts @result == 27
end

When(/^I isolate the height field$/) do
  @result = LazyCupid::Profile.parse(@page)[:height]
end

Then(/^The parser should return a height string$/) do
  puts @result
end

When(/^I isolate the smoking field$/) do
  @result = LazyCupid::Profile.parse(@page)[:smoking]
end

Then(/^The parser should return a smoking string$/) do
  puts @result
end

When(/^I isolate the drinking field$/) do
  @result = LazyCupid::Profile.parse(@page)[:drinking]
end

Then(/^The parser should return a drinking string$/) do
  puts @result
end

When(/^I isolate the location field$/) do
  @result = LazyCupid::Profile.parse(@page)[:city]
end

Then(/^The parser should return a location string$/) do
  puts @result
end

When(/^I isolate the orientation field$/) do
  @result = LazyCupid::Profile.parse(@page)[:sexuality]
end


Then(/^The parser should return a orientation string$/) do
  puts @result
end

When(/^I isolate the gender field$/) do
  @result = LazyCupid::Profile.parse(@page)[:gender]
end

Then(/^The parser should return a gender string$/) do
  puts @result
end

When(/^I isolate the status field$/) do
  @result = LazyCupid::Profile.parse(@page)[:relationship_status]
end

Then(/^The parser should return a status string$/) do
  puts @result
end

When(/^I isolate the friend_percent field$/) do
  @result = LazyCupid::Profile.parse(@page)[:friend_percentage]
end

Then(/^The parser should return a friend_percent string$/) do
  puts @result
end

When(/^I isolate the enemy_percent field$/) do
  @result = LazyCupid::Profile.parse(@page)[:enemy_percentage]
end

Then(/^The parser should return a enemy_percent string$/) do
  puts @result
end

When(/^I isolate the ethnicity field$/) do
  @result = LazyCupid::Profile.parse(@page)[:ethnicity]
end

Then(/^The parser should return a ethnicity string$/) do
  puts @result
end

When(/^I isolate the kids field$/) do
  @result = LazyCupid::Profile.parse(@page)[:kids]
end

Then(/^The parser should return something$/) do
  puts @result
end

When(/^I isolate the drugs field$/) do
  @result = LazyCupid::Profile.parse(@page)[:drugs]
end

When(/^I isolate the last_online field$/) do
  @result = LazyCupid::Profile.parse(@page)[:last_online]
end

When(/^I isolate the relative_distance field$/) do
  @result = LazyCupid::Profile.parse(@page)[:distance]
end

When(/^I isolate the inactive field$/) do
  @result = LazyCupid::Profile.parse(@page)[:inactive]
end


When(/^I isolate the intended_handle field$/) do
  @result = LazyCupid::Profile.parse(@page)[:intended_handle]
end

When(/^I isolate the a_list_name_change field$/) do
  @result = LazyCupid::Profile.parse(@page)[:a_list_name_change]
end

When(/^I login with a valid credentials$/) do
  @browser = LazyCupid::Browser.new(username: "***REMOVED***", password: "***REMOVED***", log: @log)
  @browser.login
end

Then(/^I should get login status "(.*?)"$/) do |arg1|
  puts @browser.login_status
  @browser.login_status.to_s == arg1.to_s
  @browser.logout
end

When(/^I login with invalid credentials$/) do
  @browser = LazyCupid::Browser.new(username: "doctorpkh", password: "1234", log: @log)
  @browser.login
end

When(/^I login with an account that has been deleted$/) do
  @browser = LazyCupid::Browser.new(username: "***REMOVED***", password: "***REMOVED***", log: @log)
  @browser.login
end

When(/^I login with an account that has been deactivated$/) do
  @browser = LazyCupid::Browser.new(username: "1twistedtea", password: "asdf21", log: @log)
  @browser.login
end

When(/^a CAPTCHA is present$/) do
  @browser.recaptcha?
end

When(/^I am on the messages page$/) do
  @browser = LazyCupid::Browser.new(username: "***REMOVED***", password: "***REMOVED***", log: @log)
  if @browser.login
    request_id = Time.now.to_i
    @browser.send_request("http://www.okcupid.com/messages", request_id)
    until @browser.get_request(request_id)[:ready]
      sleep 0.1
    end
    @page = @browser.get_request(request_id)[:body]
  else
    false
  end
end

Then(/"(.*?)" regular expression should return/) do |arg1|
  case arg1
  when "total messages"
    @page.match(/Message storage.*(\d+) of/)[1].is_a Integer rescue !(@page =~ /No messages\!/).nil?
  else false
  end
end
