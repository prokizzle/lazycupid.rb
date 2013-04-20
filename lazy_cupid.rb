require './includes'

class Application
  attr_reader :config, :username, :password, :db, :scheduler

  def initialize(args)
    @username     = args[ :username]
    @password     = args[ :password]
    config_path          = File.dirname($0) + '/config/'
    log_path      = File.dirname($0) + '/logs/'
    @log          = Logger.new("logs/#{@username}_#{Time.now}.log")
    @config       = Settings.new(:username => username, :path => config_path)
    @browser      = Session.new(:username => username, :password => password, :path => log_path, :log => @log)
    @browser2     = Session.new(:username => username, :password => password, :path => log_path, :log => @log)
    @browser3     = Session.new(:username => username, :password => password, :path => log_path, :log => @log)
    @db           = initialize_db
    # @prefs      = Preferences.new(:browser => @browser)
    @blocklist    = BlockList.new(:database => db, :browser => @browser)
    @search       = Lookup.new(:database => db)
    @display      = Output.new(:stats => @search, :username => username, :smart_roller => @smarty)
    @user         = Users.new(:database => db, :browser => @browser, :log => @log, :path => log_path)
    @scheduler    = Rufus::Scheduler.start_new
    @tracker      = EventTracker.new(:browser => @browser2, :database => @db, :settings => @config)
    @events       = EventWatcher.new(:browser => @browser3, :tracker => @tracker, :logger => @log)
    @harvester    = Harvester.new(
      :browser          => @browser2,
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
    filename = "./db/#{@username}.db"
    unless File.exists?(filename)
      if @browser.is_logged_in
        puts "Create new db for #{@username}?"
        choice = gets.chomp
        case choice
        when "y"
          tmp = DatabaseManager.new(:login_name => @username, :settings => @config)
          tmp.import
          tmp.close
          @first_login = true
        else
          ""
        end
      end
    end
    DatabaseManager.new(:login_name => @username, :settings => @config)
  end

  def db
    @db
  end

  def scheduler
    @scheduler
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
    [@browser3, @browser2]
  end


  def open_db
    # puts "Debug: Opening database"
    # db.open
  end

  def blocklist
    @blocklist
  end

  def test_more_matches
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
    # @browser3.login
    # @browser2.login
    secondary_login
    @browser.login
  end

  def secondary_login
    # temp = browsers_array
    # until temp.size == 0
    #   temp.shift.login
    # end
    @browser2.login
    @browser3.login
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
    harvest_home_page
    scrape_activity_feed
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
    @smarty.pre_roll_actions
  end




end

login_message = "Please login."
quit          = false
logged_in     = false

begin
  until logged_in
    print "\e[2J\e[f"
    puts "LazyCupid Main Menu","--------------------",""
    puts "#{login_message}",""
    print "Username: "
    username = gets.chomp
    password = ask("password: ") { |q| q.echo = false }
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
rescue Exception => e
  puts e.message
  puts e.backtrace
  # Exceptional.handle(e, 'Login workflow')
rescue SystemExit, Interrupt
  quit = true
  logout = false
  puts "","","Goodbye."
end

app.pre_roll_actions

app.scheduler.every '30m' do
  app.multi_scrape
end

app.scheduler.every '3h' do
  app.check_visitors
end

app.scheduler.every '5s' do
  app.check_events
end

app.scheduler.every '5m' do
  app.test_more_matches
end

app.scheduler.every '12s' do
  app.roll
end

# app.import_hidden_users

# begin
# until quit
# app.check_what_to_do
# quit = app.check_if_should_quit
# end
# rescue Exception => e
# Exceptional.handle(e)
# puts e.message
# rescue SystemExit, Interrupt
# puts "Goodbye"
# quit = true
# app.exit_db
# end

# app.scheduler.every '30min' do
#   app.check_scrape_event
# end
# app.scheduler.every '5m' do
#   app.check_if_should_visit_new_users
# end
# app.scheduler.every '1h' do
#   app.check_if_should_follow_up
# end

# app.scheduler.every '30s' do
#   puts "Idle"
# end

app.scheduler.join
