require './includes'

class YourBestState

  def initialize(username, settings)
    @user = username

    @db = DatabaseManager.new(:login_name => @user, :settings => settings)
    @state_counts = Hash.new
    @city_counts = Hash.new
  end

  def message_senders
    @db.get_all_message_senders
  end

  def increment_(item, counts)
    @item = item
    @counts = counts
    if @item.to_s[1]
      if @counts[item]
        @counts[item] += 1
      else
        @counts[item] = 1
      end
    end
    @counts
  end

  def determine_best(item)
    @counter = 0
    @item = item
    @item.each do |location, count|
      if count > @counter
        @best_item = location
        @best_count = count
      end
    end
    puts "#{@best_item}: #{@best_count}"
  end


  def run
    message_senders.each do |user, city, state|
      @state_counts = increment_(state, @state_counts)
      @city_counts = increment_(city, @city_counts)
    end
    @best_state_count = 0
    @state_counts.each do |state, count|
      if count > @best_state_count
        @best_state_count = count
        @best_state = state.to_s
      end
    end
    puts "#{@best_state}: #{@best_state_count}"
    @best_city_count = 0
    @city_counts.each do |state, count|
      if count > @best_city_count
        @best_city_count = count
        @best_city = state.to_s
      end
    end
    puts "#{@best_city}: #{@best_city_count}"
  end



end

class Settings2

  attr_reader :verbose, :debug

  def initialize
    @verbose = false
    @debug = true
  end

end

settings = Settings2.new

app = YourBestState.new(ARGV[0], settings)
app.run
