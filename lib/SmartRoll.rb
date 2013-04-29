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
    pg = @db.new_user_smart_query
    pg.each do |user|
      array.push(user["name"])
      # puts user["name"] if debug
    end

    if array.size == 0
      pg = @db.followup_query
      pg.each do |user|
        array.push(user["name"])
        # puts user["name"] if debug
      end
    end
    result = array.to_set
    result = result.to_a
    result

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
    @harvester.scrape_activity_feed
    @harvester.scrape_home_page
    check_visitors
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
    unless user == nil
      # puts user.to_s
      # @browser.go_to("http://www.okcupid.com/profile/#{user}")
      response = @user.profile(user)
      if response[:inactive]
        remove_match(user)
      else
        # puts response
        @console.log(response) if verbose
        @tally += 1
        @db.log2(response)
        autodiscover_new_users if response[:gender] == @settings.gender
      end
    else
      puts "User is nil"
      puts user
    end
  end

  def roll
    temp = next_user
    unless temp == nil
      visit_user(temp)
      @already_idle == false
    else
      puts "Idle..." unless @already_idle
      @already_idle = true
    end
  end

end
