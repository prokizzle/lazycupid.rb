class Settings
  attr_reader :max_distance, :min_percent, :min_age, :max_age, :days_ago, :preferred_state, :max_followup, :debug, :verbose, :gender

  def initialize(args)
    @account  = args[ :username]
    path      = args[ :path]
    @filename = "#{path}/#{@account}.yml"
    unless File.exists?(@filename)
      config = {
        distance: 200,
        min_percent: 60,
        min_age: 18,
        gender: 'F',
        max_age: 60,
        days_ago: 4,
        preferred_state: 'Massachusetts',
        filter_by_state: false,
        max_followup: 15,
        debug: false,
        verbose: true
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

  def max_distance
    @settings[:distance].to_i
  end

  def gender
    @settings[:gender].to_s
  end

  def min_percent
    @settings[:min_percent].to_i
  end

  def min_age
    @settings[:min_age].to_i
  end

  def max_age
    @settings[:max_age].to_i
  end

  def days_ago
    @settings[:days_ago].to_i
  end

  def preferred_state
    @settings[:preferred_state].to_s
  end

  def max_followup
    @settings[:max_followup].to_i
  end

  def filter_by_state
    @settings[:filter_by_state]
  end

  def debug
    @settings[:debug] == true
  end

  def verbose
    @settings[:verbose] == true
  end


end
