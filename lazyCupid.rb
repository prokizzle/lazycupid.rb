require './includes'

class Roller
  attr_accessor :username, :password, :speed
  attr_reader :username, :password, :speed


  def initialize(args)
    @username   = args[ :username]
    @password   = args[ :password]
    @speed      = speed
    @config     = initialize_settings
    @browser    = Session.new(:username => username, :password => password)
    @db         = initialize_db
    # @prefs    = Preferences.new(:browser => @browser)
    @blocklist  = BlockList.new(:database => db, :browser => @browser)
    @search     = Lookup.new(:database => db)
    @display    = Output.new(:stats => @search, :username => username, :smart_roller => @smarty)
    @user       = Users.new(:database => db, :browser => @browser)
    @harvester  = Harvester.new(
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
  end

  def initialize_settings
    filename = "./config/#{@username}.yml"
    unless File.exists?(filename)
      config = {distance: 200,
                min_percent: 60,
                min_age: 18,
                max_age: 60,
                days_ago: 4,
                preferred_state: 'Massachusetts',
                max_followup: 15,
                debug: true,
                verbose: true
                }
      File.open(filename, "w") do |f|
        f.write(config.to_yaml)
      end
    end
    YAML.load_file(filename)
  end

  def initialize_db
    filename = "./db/#{@username}.db"
    unless File.exists?(filename)
      puts "Create new db for #{@username}?"
      choice = gets.chomp
      case choice
      when "y"
        DatabaseManager.new(:login_name => @username, :settings => @config)
      else
        ""
      end
    else
      DatabaseManager.new(:login_name => @username, :settings => @config)
    end
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

  def clear
    @display.clear_screen
  end

  def password
    @password
  end

  def max_match_distance
    @config[:distance]
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

  def test_prefs
    puts @config[:distance]
    wait = gets.chomp
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

  def range_roll(args)
    open_db
    min = args[ :min_value]
    max = args[ :max_value]
    @smarty.run_range(min, max)
    close_db
  end

  def new_roll
    open_db
    @smarty.run_new_users_only
    close_db
  end

  def check_visitors
    open_db
    result = @harvester.visitors
    close_db
    result
  end

  def test_user_object(user)
    @browser.go_to("http://www.okcupid.com/profile/#{user}/")
    puts @user.handle
    puts @user.age
    puts @user.sexuality
    puts @user.handle
    puts @user.city
    puts @user.state
    puts @user.gender
    puts @user.relationship_status
    puts @user.match_percentage
  end

  def test_bug
    open_db
    @smarty.test_bug
    close_db
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
        sleep 60
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
  puts "#{application.check_visitors} new visitors"
  application.scrape_inbox
  application.scrape_activity_feed
  application.harvest_home_page
  application.clear
  puts "LazyCupid Main Menu","--------------------","#{username}",""
  puts "Choose Mode:"
  puts "(n) Visit new users"
  puts "(m) Monitor Visitors"
  puts "(f) Follow up"
  puts "(h) Scrape home page"
  puts "(e) Endless mode"
  puts "(a) Admin menu"
  puts "(Q) Quit",""
  print "Mode: "
  mode = gets.chomp

  case mode
  when "1"
    puts "Deprecated"
  when "n"
    application.new_roll
  when "m"
    application.check_visitors_loop
  when "f"
    application.range_roll(:min_value => 1, :max_value => application.config[:max_followup].to_i)
  when "h"
    application.harvest_home_page
  when "6"
    puts "User: "
    user = gets.chomp
    application.scrape_similar(user)
  when "7"
    application.track_msg_dates
  when "8"
    application.scrape_inbox
  when "e"
    begin
      loop do
        application.harvest_home_page
        application.scrape_activity_feed
        application.new_roll
        application.range_roll(:min_value => 1, :max_value => application.config[:max_followup].to_i)
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
    puts "(5) Populate blank genders"
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
      application.gender_fix(5)
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
