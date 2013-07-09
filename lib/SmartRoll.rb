class SmartRoll
  attr_reader :debug, :verbose, :alt_reload
  attr_accessor :alt_reload

  def initialize(args)
    @db         = args[:database]
    @blocklist  = args[:blocklist]
    @harvester  = args[:harvester]
    @user       = args[:profile_scraper]
    @browser    = args[:browser]
    @settings   = args[:settings]
    @console    = args[:gui]
    @tracker    = args[:tracker]
    @roll_list  = Array.new
    @roll_list  = reload
    @verbose    = @settings.verbose
    @debug      = @settings.debug
    @alt_reload = false
    @already_idle = true
  end

  def reload
    queue = build_user_list(@db.new_user_smart_query)
    # roll_type  = "followup"
    # if queue.empty?
    # puts "Checking for new user" if verbose
    queue = queue.concat(build_user_list(@db.followup_query))
    # roll_type  = "new_users"
    roll_type  = "mixed"
    # end
    remove_duplicates(queue)
  end

  def build_user_list(results)
    array = Array.new
    unless results == {}
      results.each do |user|
        array.push(user["name"]) if user.has_key?("name")
        # puts user["name"] if debug
      end
    end
    array
  end


  def remove_duplicates(array)
    result = array.to_set
    result.to_a
  end

  def cache
    if @roll_list.empty?
      @roll_list = reload
    else
      @roll_list
    end
  end

  def next_user
    cache.shift.to_s
  end

  def autodiscover_new_users(user)
    @harvester.scrape_from_user(user) if @settings.autodiscover_on
  end

  def remove_match(user)
    @db.delete_user(user)
  end

  def check_visitors
    viz = @tracker.parse_visitors_page
    @total_visitors += viz
    @total_visits += @tally
    @tally = 0
    puts ""
  end

  def payload
    puts "Getting new matches..." unless verbose
    3.times do
      @tracker.test_more_matches
    end
    puts "Checking for new messages..." unless verbose
    @tracker.scrape_inbox
    # check_visitors
  end

  def pre_roll_actions
    # @console.progress(@roll_list.size)
    @tally = 0
    @total_visitors = 0
    @total_visits = 0
    @start_time = Time.now.to_i
    payload
    puts "","Running..." unless verbose
  end

  def added_from(username)
    @db.get_added_from(username)
  end

  def sexuality_filter(user, sexuality)
    case sexuality
    when "Gay"
      @db.ignore_user(user) unless @settings.visit_gay == true
    when "Bisexual"
      @db.ignore_user(user) unless @settings.visit_bisexual == true
    when "Straight"
      @db.ignore_user(user) unless @settings.visit_straight == true
    end
  end

  def enemy_blocker(user)
    if user[:enemy_percentage] > user[:match_percentage]
      @db.ignore_user(user[:handle])
    end
  end



  def visit_user(user, roll_type)
    response = @user.profile(user)
    if response[:inactive]
      remove_match(user)
    else

        @db.ignore_user(response[:handle]) if response[:enemy_percentage] > response[:match_percentage]
      # puts response
      sexuality_filter(response[:handle], response[:sexuality])
      @console.log(response, added_from(user), roll_type) if verbose
      @tally += 1
      @db.log2(response)
      # @harvester.body = @user.body
      autodiscover_new_users(response) if response[:gender] == @settings.gender
    end
  end

  def roll
    current_user = next_user
    # puts "Waiting..."
    # wait = gets.chomp
    unless current_user == @db.login
      unless current_user == nil || current_user == ""
        puts ".#{current_user}." if debug
        visit_user(current_user, "disabled")
        @already_idle == false
      else
        puts "Idle..." unless @already_idle
        @already_idle = true
      end
    end
  end

end
