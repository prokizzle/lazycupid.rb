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
    @selection  = Array.new
    @selection  = reload
    @verbose    = @settings.verbose
    @debug      = @settings.debug
    @alt_reload = false
  end

  # def verbose
  #   @verbose
  # end

  # def debug
  #   @debug
  # end

  def reload
    if @alt_reload
      # puts "Checking for focus" if verbose
      results = @db.focus_query_new_users
      @query_name = "focus"
      @alt_reload = false
    else
      # puts "Checking for follow up" if verbose
      results = @db.followup_query
      @query_name = "followup"

    end

    queue = build_user_list(results)
    if queue.size == 0
      # puts "Checking for new user" if verbose
      results = @db.new_user_smart_query
      @query_name = "new users"

      queue = build_user_list(results)
    end
    # puts "#{@query_name} query returned results" if queue.size > 0
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
    if @selection.size == 0
      @selection = reload
    else
      @selection
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
    @tracker.test_more_matches
    puts "Checking for new messages..." unless verbose
    @tracker.scrape_inbox
    # check_visitors
  end

  def pre_roll_actions
    # @console.progress(@selection.size)
    @tally = 0
    @total_visitors = 0
    @total_visits = 0
    @start_time = Time.now.to_i
    payload
    puts "","Running..." unless verbose
  end

  def visit_user(user)
    response = @user.profile(user)
    if response[:inactive]
      remove_match(user)
    else
      # puts response
      @console.log(response) if verbose
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
        visit_user(current_user)
        @already_idle == false
      else
        puts "Idle..." unless @already_idle
        @already_idle = true
      end
    end
  end

end
