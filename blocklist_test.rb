require './includes'

@username = ARGV[0]
@password = ARGV[1]
@log        = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")

settings    = Settings.new(username: @username, path: File.dirname($0) + '/config/')
browser     = Browser.new(username: @username, password: @password, log: @log)
db          = DatabaseMgr.new(login_name: @username, settings: settings)
blocklist = BlockList.new(browser: browser, database: db)

print "Logging in... "

if browser.login
  puts "Success."
else
  puts "Failed."
end

blocklist.import_hidden_users