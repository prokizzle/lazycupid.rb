class SmartRoll

  def initialize(args)
    @db         = args[ :database]
    @blocklist  = args[ :blocklist]
    @harvester  = args[ :harvester]
    @user       = args[ :profile_scraper]
    @browser    = args[ :browser]
    @console    = args[ :gui]
    @settings   = args[ :settings]
    @days       = 2
    @stats      = Statistics.new
    @selection  = Array.new
    @selection  = reload
    @verbose    = @settings.verbose
    @debug      = @settings.debug
  end

  def verbose
    @verbose
  end

  def debug
    @debug
  end

  def reload
    result = @db.new_user_smart_query.to_set
    if result.size == 0
      result = @db.followup_query.to_set
    end
    result = result.to_a
    result
  end

  def cache
    if @selection.size <= 1
      @selection = reload
    else
      @selection
    end
  end

  def next_user
    cache.shift[0]
  end

  def autodiscover_new_users
    @harvester.scrape_from_user if @settings.autodiscover_on
  end

  def user_ob_debug
    begin
      test = [@user.gender, @user.handle, @user.match_percentage, @user.city, @user.state]
    rescue
      puts @browser.body
      puts "Scraping ERROR!"
      user = gets.chomp
    end
  end

  def inactive_account
    @browser.account_deleted
  end

  def remove_match(user)
    @db.delete_user(user)
  end

  def check_visitors
    viz = @harvester.visitors
    @total_visitors += viz
    @total_visits += @tally
    @tally = 0
    puts ""
  end

  def payload
    @harvester.test_more_matches
    @harvester.scrape_activity_feed
    @harvester.scrape_inbox
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
      puts user.to_s
      @browser.go_to("http://www.okcupid.com/profile/#{user}")
      if inactive_account
        remove_match(user)
      else
        user_ob_debug if debug
        @console.log(@user) if verbose
        @tally += 1
        @db.log2(@user)
        autodiscover_new_users if @user.gender == @settings.gender
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
