require_relative 'includes'

module LazyCupid

  class Application
    require 'cliutils'
    include CLIUtils::Messaging
    include CLIUtils::PrettyIO

    attr_accessor :config, :username, :password, :db, :scheduler, :blocklist, :log_path, :config_path, :smarty

    def initialize(args={})
      Dotenv.load
      if args.has_key?(:username)
        @username     = args[ :username]
        @password     = args[ :password]
      else
        @username = ENV['OKCUPID_USERNAME']
        @password = ENV['OKCUPID_PASSWORD']
      end
      @config_path   = File.dirname($0) + '/../config/'
      @log_path      = File.dirname($0) + '/../logs/'
      %x{mkdir -p #{log_path}}
         @log          = nil #Logger.new("#{log_path}#{@username}_#{Time.now}.log")
         BloatCheck.logger = Logger.new("#{log_path}bloat_#{Time.now}.log")
         @browser      = Browser.new(username: username, password: password, path: log_path, log: @log)
         @config       = Settings.new(username: username, path: config_path, browser: @browser)
         @db           = DatabaseMgr.new(login_name: @username, settings: @config, tasks: true)
         # @db2          = DatabaseMgr.new(login_name: @username, settings: @config, tasks: false)
         @blocklist    = BlockList.new(database: db, browser: @browser)
         @autorater    = AutoRater.new(username: @username, password: @password) if $auto_rate_enabled
         @display      = Output.new(username: username, smart_roller: @smarty, database: @db)
         # @user         = Users.new(database: db, browser: @browser, log: @log, path: log_path)
         @scheduler    = Rufus::Scheduler.new
         @tracker      = EventTracker.new(browser: @browser, database: @db, settings: @config)
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
         end

         def browsers_array
           [@browser, @browser]
         end

         def login_message
           @browser.login_status
         end

         def scrape_ajax_matches(number=1)
           @tracker.default_match_search(number)
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

         def rate
           @autorater.rate if $auto_rate_enabled
         end

         def delete_mutual_match_messages
           @autorater.delete_mutual_match_messages
         end

         def scrape_activity_feed
           @harvester.scrape_activity_feed
         end

         def scrape_inbox
           # delete_mutual_match_messages
           @tracker.scrape_inbox
         end

         def check_visitors
           @tracker.parse_visitors_page
         end

         def login
           @autorater.login rescue true
           @browser.login
         end

         def logout
           # @browser.agent.close
           @autorater.browser.close rescue nil
         end

         def check_events
           @events.check_events
         end

         def scrape_spotlight
           @tracker.scrape_spotlight
         end

         def unread_messages
           @events.new_mail.to_i
         end

         def roll
           @smarty.roll
         end

         def pre_roll_actions
           unless $fast_launch
             @blocklist.import_hidden_users if @config.import_hidden_users
             puts "Getting new matches..." unless $verbose
             @tracker.default_match_search
             @tracker.scrape_spotlight
             puts "Checking for new messages..." unless $verbose
             @tracker.scrape_inbox
           end
         end

         def recaptcha?
           @browser.recaptcha?
         end

         end


         class Runner
           require 'cliutils'
           require 'hr'
           include CLIUtils::Messaging
           include CLIUtils::PrettyIO

           attr_accessor :options

           def initialize(options)
            @options = options
           end

           def login_message
             return @app.login_message rescue "Please login"
           end

           def logged_in?
             return @app.login rescue false
           end

           def cli_login?
             return ARGV.size > 1
           end

           def display_login_header
             unless ARGV.size > 1
               print "\e[2J\e[f"
               messenger.section "LazyCupid Main Menu"
               Hr.print "="
               messenger.warn "#{login_message} "
               Hr.print " "
               puts ARGV[0] rescue nil
             end
           end

           def prompt_for_credentials
             @username = options["<username>"][0] if options["-u"]
             @username = ask("username: ".blue) { |q| q.echo = true} unless @username
             @password = ask("password: ".blue) { |q| q.echo = "*".cyan } unless @password
           end

           def exit_on_fail_if_cli
             if cli_login? && logged_in? == false
               puts login_message
               exit
             end
           end


           def create_login_session
             @app = Application.new(username: @username, password: @password)
             # @logged_in = @app.login
             exit_on_fail_if_cli
           end

           def login
             until logged_in?
               display_login_header
               prompt_for_credentials
               create_login_session
             end
           end


           def run

             @app.pre_roll_actions

             @app.scheduler.every "#{$scrape_inbox_frequency}", :allow_overlapping => false, :mutex => 'inbox' do
               puts "Started scraping inbox" if $verbose
               @app.scrape_inbox
               puts "Finished scraping inbox" if $verbose
             end
             #
             # app.scheduler.every '3h', :mutex => 'that_mutex' do
             # app.check_visitors
             # end

             # @app.scheduler.every '5s', :allow_overlapping => false, :mutex => 'api' do
             #   @app.check_events
             # end

             @app.scheduler.every "#{$match_frequency}m", :allow_overlapping => false, :mutex => 'tracker' do
               puts "Started scraping match search " if $verbose
               @app.scrape_ajax_matches
               @app.scrape_spotlight
               puts "Finished scraping match search " if $verbose
             end

             @app.scheduler.every '5m', :allow_overlapping => false, :mutex => 'settings' do
               puts "Reloading settings started." if $verbose
               @app.reload_settings
               puts "Reloading settings completed." if $verbose
             end

             @app.scheduler.every "#{$rate_frequency}m", :allow_overlapping => false, :mutex => 'autorater' do
               @app.rate if $auto_rate_enabled
             end

             @app.scheduler.every "#{$roll_frequency}s", :allow_overlapping => false, :mutex => 'headless' do #|job|
               @app.roll
             end

             # @app.scheduler.every '1m', :allow_overlapping => false, :mutex => 'bloat' do
             #   BloatCheck.log("some label")
             # end

             begin
               @app.scheduler.join
             rescue SystemExit, Interrupt, Exception => e
               @app.logout
               puts "\rGoodbye!"
               exit
             rescue Exception => e
               @app.logout
               puts e.message
               exit
             end
           end
         end
         end
