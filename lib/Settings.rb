class Settings
  attr_reader :max_distance,
    :min_percent,
    :min_age,
    :max_age,
    :max_height,
    :days_ago,
    :preferred_state,
    :max_followup,
    :debug,
    :verbose,
    :gender,
    :autodiscover_on,
    :distance_filter_type

  def initialize(args)
    @account  = args[ :username]
    path      = args[ :path]
    @filename = "#{path}/#{@account}.yml"
    @db_file  = "#{path}/database.yml"
    @browser     = args[ :browser]
    unless File.exists?(@filename)
      config = {geo: {
                  distance_filter_type: "distance",
                  preferred_state: " ",
                  preferred_city: " ", #match_preferences[:my_city],
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
                  min_height: 0, #flatlanders!
                  max_height: 300, #giants!
                  height_sort: "ASC", #prefer shorter
                  last_online_cutoff: 365, #ignore users not online in X days
                  visit_gay: false,
                  visit_straight: true,
                  visit_bisexual: true
                },
                visit_freq: {
                  days_ago: 5,
                  max_followup: 25
                },
                scraping: {
                  autodiscover_on: true,
                  import_hidden_users: false
                },
                growl: {
                  new_visits: false,
                  new_mail: true,
                  favorite_sign_on: false,
                  favorite_sign_off: false,
                  new_im: false
                },
                development: {
                  verbose: true,
                  debug: false
                }
                }
      File.open(@filename, "w") do |f|
        f.write(config.to_yaml)
      end
    end
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
    @settings = YAML.load_file(@filename)
    @db_settings = YAML.load_file(@db_file)
  end

  def match_preferences
    r = @browser.body_of("http://www.okcupid.com/profile", Time.now.to_i)
    gentation = r[:html].parser.xpath("//li[@id='ajax_gentation']").to_html
    ages = r[:html].parser.xpath("//li[@id='ajax_ages']").to_html
    location = r[:html].parser.xpath("//span[@id='ajax_location']")
    @looking_for = /(\w+) who like/.match(gentation)[1]
    @min_age = (/(\d{2}).+(\d{2})/).match(ages)[1]
    @max_age = (/(\d{2}).+(\d{2})/).match(ages)[2]
    @my_city = (/[\w\s]+,\s([\w\s]+)/).match(location)[1]
    # <li id="ajax_ages">Ages 20&ndash;35</li>
    {min_age: @min_age, max_age: @max_age, city: @my_city, looking_for: @looking_for}
  end

  def reload_settings
    @settings = YAML.load_file(@filename)
  end

  def distance_filter_type
    @settings[:geo][:distance_filter_type].to_s
  end

  def preferred_state
    @settings[:geo][:preferred_state].to_s
  end

  def visit_bisexual
    @settings[:matching][:visit_bisexual]
  end

  def visit_straight
    @settings[:matching][:visit_straight]
  end

  def visit_gay
    @settings[:matching][:visit_gay]
  end

  def preferred_city
    @settings[:geo][:preferred_city].to_s
  end

  def max_distance
    @settings[:geo][:distance].to_i
  end

  def import_hidden_users
    @settings[:scraping][:import_hidden_users]
  end

  def min_percent
    @settings[:matching][:min_percent].to_i
  end

  def gender
    @settings[:matching][:gender].to_s
  end

  def min_age
    @settings[:matching][:min_age].to_i
  end

  def max_age
    @settings[:matching][:max_age].to_i
  end

  def age_sort
    @settings[:matching][:age_sort].to_s
  end

  def max_height
    @settings[:matching][:max_height].to_f
  end

  def min_height
    @settings[:matching][:min_height].to_f
  end

  def height_sort
    @settings[:matching][:height_sort].to_s
  end

  def last_online_cutoff
    @settings[:matching][:last_online_cutoff].to_i
  end

  def autodiscover_on
    @settings[:scraping][:autodiscover_on] == true
  end

  def days_ago
    @settings[:visit_freq][:days_ago].to_i
  end

  def max_followup
    @settings[:visit_freq][:max_followup].to_i
  end

  def growl_new_visits
    @settings[:growl][:new_visits] == true
  end

  def growl_new_im
    @settings[:growl][:new_im] == true
  end

  def growl_new_mail
    @settings[:growl][:new_mail] == true
  end

  def growl_fave_signoff
    @settings[:growl][:favorite_sign_off] == true
  end

  def growl_fave_signon
    @settings[:growl][:favorite_sign_on] == true
  end

  def debug
    @settings[:development][:debug] == true
  end

  def verbose
    @settings[:development][:verbose] == true
  end

  def db_name
    begin
      @db_settings["development"]["database"].to_s
    rescue
      puts @db_settings
      wait = gets.chomp
    end
  end

  def db_host
    @db_settings["development"]["host"].to_s
  end

  def db_user
    @db_settings["development"]["username"].to_s
  end

  def db_pass
    @db_settings["development"]["password"].to_s
  end

  def db_adapter
    @db_settings["development"]["adapter"].to_s
  end


end
