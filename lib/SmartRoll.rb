class SmartRoll
  attr_reader :debug, :verbose

  def initialize(args)
    @db         = args[ :database]
    @blocklist  = args[ :blocklist]
    @harvester  = args[ :harvester]
    @user       = args[ :profile_scraper]
    @browser    = args[ :browser]
    @settings   = args[ :settings]
    @console    = args[:gui]
    @tracker    = args[ :tracker]
    @days       = 2
    @selection  = Array.new
    @selection  = reload
    @verbose    = @settings.verbose
    @debug      = @settings.debug
  end

  # def verbose
  #   @verbose
  # end

  # def debug
  #   @debug
  # end

  def reload
    array = Array.new
    pg = @db.followup_query
    unless pg == {}
      pg.each do |user|
        array.push(user["name"]) if user.has_key?("name")
        # puts user["name"] if debug
      end
    end

    if array.size == 0
      pg = @db.new_user_smart_query
      unless pg == {}
        pg.each do |user|
          array.push(user["name"]) if user.has_key?("name")
          # puts user["name"] if debug
        end
      end
    end
    remove_duplicates(array)
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
    cache.shift
  end

  def autodiscover_new_users
    @harvester.scrape_from_user if @settings.autodiscover_on
  end

  def inactive_account
    @browser.account_deleted
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
    @tracker.test_more_matches
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
      autodiscover_new_users if response[:gender] == @settings.gender
    end
  end

  def roll
    temp = next_user.to_s
    # puts "Waiting..."
    # wait = gets.chomp
    unless temp == @db.login
      unless temp == nil || temp == ""
        puts ".#{temp}."
        visit_user(temp)
        @already_idle == false
      else
        puts "Idle..." unless @already_idle
        @already_idle = true
      end
    end
  end

end
