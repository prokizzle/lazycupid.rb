require './includes'

class Application
  attr_reader :config, :username, :password, :db, :scheduler, :blocklist

  def initialize(args)
    @username     = args[ :username]
    @password     = args[ :password]
    config_path          = File.dirname($0) + '/config/'
    log_path      = File.dirname($0) + '/logs/'
    @db_path      = File.dirname($0) + '/db/'
    @log          = Logger.new("logs/#{@username}_#{Time.now}.log")
    @config       = Settings.new(:username => username, :path => config_path)
    @db           = DatabaseMgr.new(:login_name => @username, :settings => @config)
    @browser      = Browser.new(:username => username, :password => password, :path => log_path, :log => @log)
    @blocklist    = BlockList.new(:database => db, :browser => @browser)
    @search       = Lookup.new(:database => db)
    @display      = Output.new(:stats => @search, :username => username, :smart_roller => @smarty)
    @user         = Users.new(:database => db, :browser => @browser, :log => @log, :path => log_path)
    @scheduler    = Rufus::Scheduler.start_new
    @tracker      = EventTracker.new(:browser => @browser, :database => @db, :settings => @config)
    @events       = EventWatcher.new(:browser => @browser, :tracker => @tracker, :logger => @log)
    @harvester    = Harvester.new(
      :browser          => @browser,
      :database         => db,
      :profile_scraper  => @user,
      :settings         => @config,
    :events             => @events)
    @smarty       = SmartRoll.new(
      :database         => db,
      :blocklist        => blocklist,
      :harvester        => @harvester,
      :profile_scraper  => @user,
      :tracker          => @tracker,
      :browser          => @browser,
      :gui              => @display,
    :settings           => @config)
    @first_login        = false
    @scrape_event_time  = 0
    @quit_event_time    = Chronic.parse('3 days from now')
    is_idle             = false
    @idle               = Time.now.to_i

  end

  def initialize_db
    DatabaseManager.new(:login_name => @username, :settings => @config, :db_path => @db_path)
  end

  def is_idle
    @is_idle
  end

  def close_db
    # puts "Debug: Closing database."
    # db.close
  end

  def exit_db
    db.close
  end

  def browsers_array
    [@browser, @browser]
  end


  def open_db
    # puts "Debug: Opening database"
    # db.open
  end

  def scrape_ajax_matches
    @tracker.test_more_matches
  end

  def get_new_user_counts
    result = db.count_new_user_smart_query
    result.to_i
  end

  def get_follow_up_counts
    result = db.get_counts_of_follow_up
    result
  end

  def import_hidden_users
    @blocklist.import_hidden_users
  end


  def harvest_home_page
    @harvester.scrape_home_page
  end

  def scrape_activity_feed
    @harvester.scrape_activity_feed
  end

  def scrape_inbox
    @tracker.scrape_inbox
  end

  def check_visitors
    @tracker.parse_visitors_page
  end

  def login
    # until browsers.size == 0
    #   browsers.shift.login
    # end
    # @browser.login
    # @browser.login
    # secondary_login
    @browser.login
  end

  def secondary_login
    # temp = browsers_array
    # until temp.size == 0
    #   temp.shift.login
    # end
    @browser.login
    @browser.login
  end

  def secondary_logout
    temp = browsers_array
    until temp.size == 0
      temp.shift.logout
    end
  end

  def logout
    secondary_logout
    @browser.logout
  end

  def range_roll
    begin
      @smarty.run_range
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

  def new_roll
    begin
      @smarty.run_new_users_only
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

  def multi_scrape
    # harvest_home_page
    # scrape_activity_feed
    scrape_inbox
  end

  def check_if_should_quit
    Time.now.to_i >= @quit_event_time.to_i
  end

  # def check_scrape_event
  #   multi_scrape if @scrape_event_time.to_i <= Time.now.to_i
  # end

  def check_if_should_visit_new_users
    new_roll if get_new_user_counts >= 100
  end

  def check_if_should_follow_up
    range_roll if get_follow_up_counts >= 50
  end

  def check_what_to_do
    if get_follow_up_counts >= 40
      range_roll
    elsif get_new_user_counts >= 50
      new_roll
    else
      if @idle >= Time.now.to_i
        puts "Idle"
        @idle = Chronic.parse('10 min from now').to_i
      end
    end
  end

  def visitor_event
    @tracker.visitor_event
  end

  def check_events
    @events.check_events
  end

  def roll
    @smarty.roll
  end

  def pre_roll_actions
    # @blocklist.import_hidden_users
    @smarty.pre_roll_actions
  end

  def set_stop_time
    @stop_time = Chronic.parse('4h from now').to_i
  end

end

login_message = "Please login."
quit          = false
logged_in     = false


until logged_in
  unless ARGV.size > 0
    print "\e[2J\e[f"
    puts "LazyCupid Main Menu","--------------------",""
    puts "#{login_message}",""
    print "Username: "
    username = gets.chomp
    password = ask("password: ") { |q| q.echo = false }
  else
    # puts "#{login_message}",""
    username = ARGV[0]
    password = ARGV[1]
  end
  # Exceptional.rescue do
  app = Application.new(:username => username, :password => password)
  # end
  if app.login
    logged_in = true
    login_message = "Success. Initializing."
    print "\e[2J\e[f"
  else
    login_message = "Incorrect password. Try again."
  end
end
# rescue Exception => e
# puts e.message
# puts e.backtrace
# Exceptional.handle(e, 'Login workflow')
# rescue SystemExit, Interrupt
# quit = true
# logout = false
# puts "","","Goodbye."
# end
#

# app.set_stop_time

app.pre_roll_actions
app.scheduler.every '30m', :mutex => 'that_mutex' do
  app.scrape_inbox
end
#
# app.scheduler.every '3h', :mutex => 'that_mutex' do
  # app.check_visitors
# end

app.scheduler.every '5s', :allow_overlapping => false, :mutex => 'that_mutex' do
  app.check_events
end

app.scheduler.every '5m', :mutex => 'that_mutex' do
  app.scrape_ajax_matches
end

app.scheduler.every '6s', :allow_overlapping => false, :mutex => 'that_mutex' do #|job|
  # if Time.now.to_i >= @stop_time.to_i
    # puts "Roll session complete."
    # job.unschedule
  # else
  # loop do
    app.roll
  # end
  # end
end

app.scheduler.join
