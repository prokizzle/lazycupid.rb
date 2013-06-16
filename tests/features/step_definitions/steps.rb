require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "includes.rb"))

Before do
  @account = "***REMOVED***"
  @settings = Settings.new(username: @account, path: File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "config")))
  @db = DatabaseMgr.new(login_name: @account, settings: @settings)
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