require './includes'

class Settings2
  attr_reader :verbose, :debug
end

@config = Settings2.new

@username = ARGV[0]
@password = ARGV[1]

log_path      = File.dirname($0) + '/logs/'
db            = DatabaseMgr.new(:login_name => @username, :settings => @config)
@log          = Logger.new("logs/test_#{Time.now}.log")
@browser      = Browser.new(:username => @username, :password => @password, :path => log_path, :log => @log)
@user         = Users.new(:database => db, :browser => @browser, :log => @log, :path => log_path)

@browser.login
result = @user.profile("***REMOVED***")
hash = @browser.hash
puts hash
puts result
@browser.logout