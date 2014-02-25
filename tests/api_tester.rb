require_relative '../lib/LazyCupid/includes'
# [todo] - bring up to date with latest changes to event_watcher and browser
# [fix] - make api_tester work
# [todo] - do elongated testing against okcupid api
# [todo] - rework the event parser
# [todo] - rework the already-see-events tracking system (the de-duplicator)


@debug = true

@log        = Logger.new("logs/#{ARGV[0]}_#{Time.now}.log")

@hash       = Hash.new { |hash, key| hash[key] =  0}
@spotlight  = Hash.new
@username   = ARGV[0]

settings    = LazyCupid::Settings.new(:username => @username, :path => File.dirname($0) + '/../config/')

db          = LazyCupid::DatabaseMgr.new(:login_name => @username, :settings => settings)
browser     = LazyCupid::Browser.new(:username => @username, :password => ARGV[1], :log => @log)
tracker     = LazyCupid::EventTracker.new(:browser => browser, :database => db, :settings => settings)
api         = LazyCupid::EventWatcher.new(:browser => browser, :tracker => tracker, :logger => Logger.new("logs/#{@username}_#{Time.now}.log"))
api_events  = LazyCupid::APIEvents.new(:tracker => tracker)
print "Logging in... "

if api.login
  puts "Success."
else
  puts "Failed."
end


loop do
  api.check_events
end
