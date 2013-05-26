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
    unless File.exists?(@filename)
      config = {geo: {
                  :distance_filter_type => "distance",
                  :preferred_state => " ",
                  :preferred_city => " ",
                  :distance => 150
                },
                matching: {
                  :min_percent => 50,
                  :friend_percent => 0,
                  :enemy_percent => 0,
                  :min_age => 18,
                  :max_age => 45,
                  :age_sort => "ASC", #prefer younger
                  :gender => "F",
                  :min_height => 0, #flatlanders!
                  :max_height => 300, #giants!
                  :height_sort => "ASC", #prefer shorter
                },
                visit_freq: {
                  :days_ago => 3,
                  :max_followup => 15
                },
                scraping: {
                  :autodiscover_on => true
                },
                development: {
                  :verbose => true,
                  :debug => false
                }
                }
      File.open(@filename, "w") do |f|
        f.write(config.to_yaml)
      end
    end
    @settings = YAML.load_file(@filename)
    @db_settings = YAML.load_file(@db_file)
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

  def preferred_city
    @settings[:geo][:preferred_city].to_s
  end

  def max_distance
    @settings[:geo][:distance].to_i
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

  def autodiscover_on
    @settings[:scraping][:autodiscover_on] == true
  end

  def days_ago
    @settings[:visit_freq][:days_ago].to_i
  end

  def max_followup
    @settings[:visit_freq][:max_followup].to_i
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
