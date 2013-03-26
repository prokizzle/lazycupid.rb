require './includes'

class Application

  def initialize(args)
    Exceptional.rescue do
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
      @scrape_event_time = Time.now.to_i
    end
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


  def config
    @config
  end

  def username
    @username
  end

  def password
    @password
  end

  def db
    @db
  end

  def close_db
    # puts "Debug: Closing database."
    db.close
  end

  def open_db
    # puts "Debug: Opening database"
    db.open
  end

  def blocklist
    @blocklist
  end

  def test_more_matches
    open_db
    @harvester.test_more_matches
    close_db
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

  def ignore_hidden_users
    open_db
    @blocklist.import_hidden_users
    close_db
  end

  def logout
    @browser.logout
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

  def scrape_inbox
    open_db
    @harvester.scrape_inbox
    close_db
  end

  def check_visitors
    open_db
    result = @harvester.visitors
    close_db
    result
  end

  def login
    @browser.login
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

  def multi_scrape
    harvest_home_page
    scrape_activity_feed
    scrape_inbox
    check_visitors
    @scrape_event_time = Chronic.parse('30 minutes from now').to_i
  end

  def check_if_should_quit
    false
  end

  def check_scrape_event
    multi_scrape if @scrape_event_time <= Time.now.to_i
  end

  def check_if_should_visit_new_users
    new_roll if get_new_user_counts >= 100
  end

  def check_if_should_follow_up
    range_roll if get_follow_up_counts >= 50
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
rescue SystemExit, Interrupt
  quit = true
  logout = false
  puts "","","Goodbye."
end


until quit
  app.check_scrape_event
  app.check_if_should_visit_new_users
  app.check_if_should_follow_up
  quit = app.check_if_should_quit
end
