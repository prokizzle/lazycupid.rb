require './includes'

class Roller
  attr_accessor :username, :password, :speed, :first_login
  attr_reader :username, :password, :speed, :first_login


  def initialize(args)
    @username     = args[ :username]
    @password     = args[ :password]
    path          = File.dirname($0) + '/config/'
    @config       = Settings.new(:username => username, :path => path)
    @browser      = Session.new(:username => username, :password => password)
    @db           = initialize_db
    # @prefs      = Preferences.new(:browser => @browser)
    @blocklist    = BlockList.new(:database => db, :browser => @browser)
    @search       = Lookup.new(:database => db)
    @display      = Output.new(:stats => @search, :username => username, :smart_roller => @smarty)
    @user         = Users.new(:database => db, :browser => @browser)
    @harvester    = Harvester.new(
      :browser => @browser,
      :database => db,
      :profile_scraper => @user,
    :settings => @config)
    @smarty     = SmartRoll.new(
      :database => db,
      :blocklist => blocklist,
      :harvester => @harvester,
      :profile_scraper => @user,
      :browser => @browser,
      :gui => @display,
    :settings => @config)
    @first_login = false
  end

  def initialize_db
    filename = "./db/#{@username}.db"
    unless File.exists?(filename)
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
      DatabaseManager.new(:login_name => @username, :settings => @config)
  end

  def fix_dates
    open_db
    @smarty.fix_blank_dates
    close_db
  end

  def blocklist
    @blocklist
  end

  def username
    @username
  end

  def scrape_matches_page
    open_db
    @harvester.scrape_matches_page
    close_db
  end

  def test_more_matches
    open_db
    @harvester.test_more_matches
    close_db
  end

  def clear
    @display.clear_screen
  end

  def password
    @password
  end

  def max_match_distance
    @config.max_distance
  end

  def min_match_percent
    # Settings.match_preferences[:min_percent]
    # @config['min_percent']
  end

  def min_match_age
    # Settings.match_preferences[:min_age]
    # @config['min_age']
  end

  def max_match_age
    # Settings.match_preferences[:max_age]
    # @config['max_age']
  end

  def get_new_user_counts
    open_db
    result = db.count_new_user_smart_query
    close_db
    result.to_i
  end

  def get_follow_up_counts
    open_db
    result = db.get_counts_of_follow_up
    close_db
    result
  end

  def db
    @db
  end

  def visit_newbs
    open_db
    @smarty.run2
    close_db
  end

  def ignore_user(user)
    open_db
    @blocklist.add(user)
    close_db
  end

  def gender_fix(d)
    open_db
    @smarty.gender_fix(d)
    close_db
  end

  def reset_ignored_list
    open_db
    db.reset_ignored_list
    close_db
  end

  def close_db
    # puts "Debug: Closing database."
    db.close
  end

  def open_db
    # puts "Debug: Opening database"
    db.open
  end

  def ignore_hidden_users
    open_db
    @blocklist.import_hidden_users
    close_db
  end

  def search(user)
    open_db
    @search.byUser(user)
    close_db
  end

  def logout
    @browser.logout
  end

  def config
    @config
  end

  def logged_in
    @browser.is_logged_in
  end

  def harvest_home_page
    open_db
    @harvester.scrape_home_page
    close_db
  end

  def reload_settings
    @config.reload_settings
  end

  def scrape_activity_feed
    open_db
    @harvester.scrape_activity_feed
    close_db
  end

  def login
    @browser.login
  end

  def add(user)
    open_db
    @db.add_user(user)
    close_db
  end

  def range_roll
    open_db
    @smarty.run_range
    close_db
  end

  def new_roll
    open_db
    @smarty.run_new_users_only
    close_db
  end

  def first_login
    @first_login
  end

  def welcome
    first_login = false
    puts "Welcome to Lazy Cupid, the easiest way to get noticed"
    puts "on OKCupid. Using this will give you an unparalleled"
    puts "advantage on this site. Be prepared for lots of new"
    puts "attention."
    puts "","Press enter to begin..."
    wait = gets.chomp
    ignore_hidden_users
    new_roll
  end

  def check_visitors
    open_db
    result = @harvester.visitors
    close_db
    result
  end


  # def test_prefs
  #   @prefs.get_match_preferences
  # end


  def scrape_similar(user)
    open_db
    @harvester.similar_user_scrape(user)
    close_db
  end

  def scrape_inbox
    open_db
    @harvester.scrape_inbox
    close_db
  end

  def track_msg_dates
    open_db
    @harvester.track_msg_dates
    close_db
  end

  def check_visitors_loop
    open_db
    puts "Monitoring visitors"
    begin
      loop do
        puts "#{@harvester.visitors} new visitors"
        sleep 240
      end
    rescue SystemExit, Interrupt
    end
    close_db
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
    application = Roller.new(:username => username, :password => password)
    if application.login
      logged_in = true
      login_message = "Success. Initializing."
      print "\e[2J\e[f"
      puts "LazyCupid Main Menu","--------------------",""
      puts "#{login_message}",""
    else
      login_message = "Incorrect password. Try again."
    end
  end
rescue SystemExit, Interrupt
  quit = true
  logout = false
  puts "","","Goodbye."
end
until quit
  # puts "#{application.check_visitors} new visitors"
  # application.scrape_inbox
  # application.scrape_activity_feed
  # application.harvest_home_page
      application.welcome if application.first_login
  application.clear
  puts "LazyCupid Main Menu","--------------------","#{username}",""
  puts "Choose Mode:"
  puts "(n) Visit new users (#{application.get_new_user_counts})" if application.get_new_user_counts >= 100
  puts "(m) Monitor Visitors"
  puts "(f) Follow up (#{application.get_follow_up_counts})" if application.get_follow_up_counts >= 50
  puts "(s) Scrape matches"
  puts "(e) Endless mode"
  puts "(a) Admin menu"
  puts "(Q) Quit",""
  print "Mode: "
  mode = gets.chomp

  case mode
  when "n"
    application.new_roll
  when "m"
    application.check_visitors_loop
  when "f"
    application.range_roll
  when "s"
    application.scrape_matches_page
  when "6"
    puts "User: "
    user = gets.chomp
    application.scrape_similar(user)
  when "7"
    application.test_more_matches
  when "e"
    begin
      loop do
        application.harvest_home_page
        sleep 10
        application.scrape_activity_feed
        sleep 10
        application.scrape_matches_page
        sleep 10
        application.new_roll if application.get_new_user_counts >= 100
        application.range_roll if application.get_follow_up_counts >= 100
        # application.range_rollq
        # (:min_value => 1, :max_value => 10)
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    rescue SystemExit, Interrupt
    end
  when "10"
    application.test_prefs
  when "b"
    application.test_bug
  when "a"
    puts "Admin Menu","-----"
    puts "(1) Add User"
    puts "(2) Lookup visit counts"
    puts "(3) Block user"
    puts "(4) Auto import hidden users to blocklist"
    puts "(5) Reload settings file"
    puts "(6) Reset ignored list"
    choice = gets.chomp
    case choice
    when "1"
      print "User to add: "
      user = gets.chomp
      application.add(user)
    when "2"
      puts ""
      print "User: "
      user = gets.chomp
      print "You have visited #{user} "
      puts application.search(user).to_s + " times."
      sleep 5
    when "3"
      print "User: "
      user = gets.chomp
      application.ignore_user(user)
    when "4"
      application.ignore_hidden_users
    when "5"
      application.reload_settings
    when "6"
      application.reset_ignored_list
    end
  when "q"
    quit = true
    @logout = true
    application.close_db
  when "Q"
    quit = true
    @logout = true
    application.close_db
  else
    puts "Invalid selection."
  end
end
if @logout
  login_message = "Logging out."
  print "\e[2J\e[f"
  puts "LazyCupid Main Menu","--------------------",""
  puts "#{login_message}",""
  application.logout
  application.clear
  application.close_db
end
puts ""
