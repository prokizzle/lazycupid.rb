require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "includes.rb"))

Before do
@settings = Settings.new(username: "***REMOVED***", path: File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config")))
@db = DatabaseMgr.new(login_name: "***REMOVED***", settings: @settings)
@db.delete_user("fake_user")
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