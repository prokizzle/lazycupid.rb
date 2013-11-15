require_relative 'includes'

module LazyCupid
  class Application
    attr_reader :config, :username, :password, :db, :scheduler, :blocklist

    def initialize(args)
      @username     = args[ :username]
      @password     = args[ :password]
      config_path   = File.dirname($0) + '/../config/'
      log_path      = File.dirname($0) + '/../logs/'
      @log          = Logger.new("#{log_path}#{@username}_#{Time.now}.log")
      BloatCheck.logger = Logger.new("#{log_path}bloat_#{Time.now}.log")
      @browser      = Browser.new(username: username, password: password, path: log_path, log: @log)
      @config       = Settings.new(username: username, path: config_path, browser: @browser)
      @db           = DatabaseMgr.new(login_name: @username, settings: @config, tasks: true)
      @db2          = DatabaseMgr.new(login_name: @username, settings: @config, tasks: false)
      @blocklist    = BlockList.new(database: db, browser: @browser)
      @search       = Lookup.new(database: db)
      @display      = Output.new(stats: @search, username: username, smart_roller: @smarty)
      # @user         = Users.new(database: db, browser: @browser, log: @log, path: log_path)
      @scheduler    = Rufus::Scheduler.start_new
      @tracker      = EventTracker.new(browser: @browser, database: @db2, settings: @config)
      @events       = EventWatcher.new(browser: @browser, tracker: @tracker, logger:  @log, settings: @config)
      @harvester    = Harvester.new(
        browser:           @browser,
        database:          db,
        # profile_scraper:   @user,
        settings:          @config,
      events:              @events)
      @smarty       = SmartRoll.new(
        database:          db,
        blocklist:         blocklist,
        harvester:         @harvester,
        # profile_scraper:   @user,
        tracker:           @tracker,
        browser:           @browser,
        gui:               @display,
      settings:            @config)
      @first_login        = false
      @scrape_event_time  = 0
      @quit_event_time    = Chronic.parse('3 days from now')
      is_idle             = false
      @idle               = Time.now.to_i
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

    def login_message
      @browser.login_status
    end

    def scrape_ajax_matches
      @tracker.default_match_search
    end

    def scrape_ajax_new_matches
      @tracker.focus_new_users
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

    def reload_settings
      @config.reload_config
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
      @browser.login
    end

    def logout
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

    def unread_messages
      @events.new_mail.to_i
    end

    def roll
      @smarty.roll
    end

    def pre_roll_actions
      @blocklist.import_hidden_users if @config.import_hidden_users
      @smarty.pre_roll_actions
    end

    def set_stop_time
      @stop_time = Chronic.parse('4h from now').to_i
    end

    def run_new_user_focus_crawl
      # @smarty.alt_reload = true
    end

    def recaptcha?
      @browser.recaptcha?
    end

  end


  class Runner

    def login
      login_message = "Please login."
      quit          = false
      logged_in     = false

      cli_login = true if ARGV.size > 1
      until logged_in
        unless cli_login
          print "\e[2J\e[f"
          puts "LazyCupid Main Menu","--------------------",""
          puts "#{login_message}",""
          username = ask("username: ") { |q| q.echo = true}
          password = ask("password: ") { |q| q.echo = "*" }
        else
          username = ARGV[0]
          password = ARGV[1]
        end
        @app = Application.new(username: username, password: password)
        if @app.login
          logged_in = true
          login_message = @app.login_message
          print "\e[2J\e[f"
        else
          login_message = @app.login_message
          puts login_message if cli_login
          exit if cli_login
        end
      end
    end


    def run
      # @app.set_stop_time

      @app.pre_roll_actions

      @app.scheduler.every '30m', :allow_overlapping => false, :mutex => 'tracker' do
        @app.scrape_inbox
      end
      #
      # app.scheduler.every '3h', :mutex => 'that_mutex' do
      # app.check_visitors
      # end

      @app.scheduler.every '5s', :allow_overlapping => false, :mutex => 'tracker' do
        @app.check_events
      end

      # @app.scheduler.every "#{$match_frequency}m", :allow_overlapping => false, :mutex => 'tracker' do
        # @app.scrape_ajax_matches
      # end

      @app.scheduler.every '5m', :allow_overlapping => false, :mutex => 'settings' do
        @app.reload_settings
      end

      @app.scheduler.every "#{$roll_frequency}s", :allow_overlapping => false, :mutex => 'roller' do #|job|
        @app.roll
      end

      # @app.scheduler.every '1m', :allow_overlapping => false, :mutex => 'bloat' do
      #   BloatCheck.log("some label")
      # end

      @app.scheduler.join
    end

    def menu
      puts "Menu"
      puts "1. Rolls"
      print "2. Monitor"
      choice = ask(":") {|q| q.echo = true}
      case choice
      when "1"
        interactive_roll
      when "2"
        monitor_visitors
      end
    end


    def interactive_roll
      rolls = ask("Rolls: ") {|q| q.echo = true}
      rolls.to_i.times do
        @app.roll
        sleep 6
      end
    end

    def monitor_visitors
      begin
        loop do
          @app.check_events
        end
      rescue Interrupt, SystemExit
      end
    end

  end
end
