class Settings
  attr_reader :max_distance,
              :min_percent,
              :min_age,
              :max_age,
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
    unless File.exists?(@filename)
      config = {geo: {
                  :distance_filter_type => "state",
                  :preferred_state => "California",
                  :preferred_city => "San Diego",
                  :distance => 8000
                          },
                matching: {
                  :min_percent => 50,
                  :friend_percent => 0,
                  :enemy_percent => 0,
                  :min_age => 18,
                  :max_age => 45,
                  :gender => "F"
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


end
