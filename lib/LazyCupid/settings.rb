require 'yaml'

module LazyCupid
  class Settings
    attr_reader :distance_filter_type, :preferred_state, :visit_bisexual, :visit_gay, :visit_straight, :preferred_city, :max_distance,
      :import_hidden_users, :min_percent, :gender, :min_age, :max_age, :age_sort, :max_height, :min_height, :height_sort,
      :last_online_cutoff, :autodiscover_on, :days_ago, :max_followup, :debug, :verbose, :db_name, :db_host, :db_user, :db_pass, :db_adapter


    def initialize(args)
      @account  = args[ :username]
      path      = args[ :path]
      @filename = "#{path}/#{@account}.yml"
      @db_file  = "#{path}/database.yml"
      unless File.exists?(@db_file)
        db_ = {
          development: {
            adapter: "postgresql",
            host: "localhost",
            username: "postgres",
            password: "123456",
            database: "lazy_cupid"
          }
        }
        File.open(@db_file, "w") do |f|
          f.write(db_.to_yaml)
        end
      end
      unless File.exists?(@filename)
        # [todo] - add default options for readability score filtering
        # Create generic preference file
        config = {geo: {
                    distance: 50
                  },
                  matching: {
                    min_percent: 50,
                    friend_percent: 0,
                    enemy_percent: 0,
                    min_age: 18, #match_preferences[:min_age],
                    max_age: 50, #match_preferences[:max_age],
                    age_sort: "ASC", #prefer younger
                    gender: "F",
                    alt_gender: "R",
                    min_height: 0, #flatlanders!
                    max_height: 300, #giants!
                    height_sort: "ASC", #prefer shorter
                    last_online_cutoff: 365, #ignore users not online in X days
                    visit_gay: false,
                    visit_straight: true,
                    visit_bisexual: true
                  },
                  visit_freq: {
                    days_ago: 10,
                    max_followup: 2,
                    roll_frequency: 6 #in seconds
                  },
                  scraping: {
                    autodiscover_on: true,
                    import_hidden_users: false,
                    match_frequency: 2, #in minutes,
                    scrape_match_search: false #off until viable solution found
                  },
                  development: {
                    verbose: true,
                    debug: false
                  }
                  }
        File.open(@filename, "w") do |f|
          f.write(config.to_yaml)
        end
        puts "Exiting... restart app after setting your config preferences"
        exit
      end
      # Load preference file
      @settings = YAML.load_file(@filename)

      # Load database config
      @db_settings = YAML.load_file(@db_file)

      # [todo] - add support for readability score filtering

      # Load settings attributes into variables for external reference
      @max_distance           = @settings[:geo][:distance].to_i
      @visit_bisexual         = @settings[:matching][:visit_bisexual]
      @visit_straight         = @settings[:matching][:visit_straight]
      @visit_gay              = @settings[:matching][:visit_gay]
      @min_percent            = @settings[:matching][:min_percent].to_i
      @gender                 = @settings[:matching][:gender].to_s
      @alt_gender             = @settings[:matching][:alt_gender].to_s
      @min_age                = @settings[:matching][:min_age].to_i
      @max_age                = @settings[:matching][:max_age].to_i
      @age_sort               = @settings[:matching][:age_sort].to_s
      @max_height             = @settings[:matching][:max_height].to_f
      @min_height             = @settings[:matching][:min_height].to_f
      @height_sort            = @settings[:matching][:height_sort].to_s
      @last_online_cutoff     = @settings[:matching][:last_online_cutoff].to_i
      @days_ago               = @settings[:visit_freq][:days_ago].to_i
      @max_followup           = @settings[:visit_freq][:max_followup].to_i
      @roll_frequency         = @settings[:visit_freq][:roll_frequency].to_s
      @import_hidden_users    = @settings[:scraping][:import_hidden_users]
      @match_frequency        = @settings[:scraping][:match_frequency]
      @autodiscover_on        = @settings[:scraping][:autodiscover_on]  == true
      @scrape_match_search    = @settings[:scraping][:scrape_match_search]      == true

      @debug                  = @settings[:development][:debug]         == true
      @verbose                = @settings[:development][:verbose]       == true
      @db_name                = @db_settings["development"]["database"].to_s
      @db_host                = @db_settings["development"]["host"].to_s
      @db_user                = @db_settings["development"]["username"].to_s
      @db_pass                = @db_settings["development"]["password"].to_s
      @db_adapter             = @db_settings["development"]["adapter"].to_s

      # Global variables for mid-session reloads

      $max_distance     = @max_distance
      $min_percent      = @min_percent
      $verbose          = @verbose
      $debug            = @debug
      $roll_frequency   = @roll_frequency
      $match_frequency  = @match_frequency
      $gender           = @gender
      $alt_gender       = @alt_gender
      $scrape_match_search    = @scrape_match_search
    end

    def reload_config
      settings          = YAML.load_file(@filename)

      $max_distance     = settings[:geo][:distance].to_i
      $min_percent      = settings[:matching][:min_percent].to_i
      $verbose          = settings[:development][:verbose]       == true
      $debug            = settings[:development][:debug]         == true
      $roll_frequency   = settings[:visit_freq][:roll_frequency].to_s
      $match_frequency  = settings[:scraping][:match_frequency].to_s
      $scrape_match_search = settings[:scraping][:scrape_match_search]      == true


    end

  end
end
