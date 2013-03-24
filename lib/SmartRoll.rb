class SmartRoll
  attr_reader :max, :delete, :mode, :days
  attr_accessor :max, :delete, :mode, :days

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
    @verbose    = @settings.verbose
    @debug      = @settings.debug
  end

  def sexuality(user)
    result = @database.get_sexuality(user)
    result[0][0].to_s
  end

  def verbose
    @verbose
  end

  def debug
    @debug
  end

  def gender(user)
    result = @database.get_gender(user)
    result[0][0].to_s
  end

  def is_male(user)
    begin
      gender(user) == 'M'
    rescue
      false
    end
  end

  def is_female(user)
    gender(user) == 'F'
  end

  def remove_duplicates(array)
    s = array.to_set
    a = s.to_a
  end

  def relative_last_visit(match)
    unix_date2 = @db.get_my_last_visit_date(match)
    ((Time.now.to_i - unix_date2)/86400).round
  end

  def days_ago(num)
    Chronic.parse("#{num} days ago").to_i
  end

  def build_queues_new_users
    @selection = @db.new_user_smart_query
  end

  def build_queue_no_gender(days)
    @selection = @db.no_gender(days_ago(days))
    puts "#{@selection.size} users queued up."
    sleep 2
  end

  def build_range
    @selection = @db.followup_query
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

  def check_for_new_visitors
    @harvester.visitors
  end

  def new_messages
    @browser.body.match(/.badge..\d+<\/span>/)[2].to_i
  end



  def unix_time
    Time.now.to_i
  end

  def inactive_account
    @browser.account_deleted
  end

  def remove_match(user)
    @db.delete_user(user)
  end



  def event_time
    @event_time
  end

  def visitor_count
    @harvester.visitors
  end

  def stats
    {:total_visits => @total_visits, :total_visitors => @total_visitors, :start_time => @start_time.to_i}
  end

  def check_visitors
    viz = @harvester.visitors
    # puts "************************"
    # puts "Vistors:  #{viz}"
    # puts "Visited:  #{@tally}"
    # puts "************************"
    @total_visitors += viz
    @total_visits += @tally
    # @console.update_progress(@total_visits)
    @console.dashboard(@total_visits, @total_visitors, @start_time, @tally, @current_state)
    # puts "Ratio: #{(viz/@tally).to_f}"
    @event_time = Chronic.parse('5 minutes from now').to_i
    @tally = 0
    puts ""
  end

  def payload
    @db.open
    @harvester.test_more_matches
    @harvester.scrape_activity_feed
    @harvester.scrape_inbox
    @harvester.scrape_home_page
    check_visitors
    @db.close
  end

  def summary
    payload
    puts ""
    puts "Results: "
    puts "Visited:  #{@total_visits} people"
    puts "Visitors: #{@total_visitors}"
    sleep 4
  end

  def pre_roll_actions
    @console.progress(@selection.size)
    @tally = 0
    @total_visitors = 0
    @total_visits = 0
    @start_time = Time.now.to_i
    payload
  end

  def visit_user(user)
    @db.open
    @browser.go_to("http://www.okcupid.com/profile/#{user}/", user)
    if inactive_account
      remove_match(user)
    else
      user_ob_debug if debug
      @console.log(@user) if verbose
      @tally += 1
      @db.log2(@user)
      @current_state = @user.state
      autodiscover_new_users if @user.gender == @settings.gender
    end
    @db.close
  end

  def roll
    begin
      # @bar = ProgressBar.new(@selection.size)
      pre_roll_actions
      @selection.each do |user, _, _, _|
        visit_user(user)
        sleep 6
        payload if unix_time >= event_time
      end
    rescue Interrupt, SystemExit
    end
    summary
  end

  def gender_fix(days)
    build_queue_no_gender(days)
    roll
  end

  def run_range
    build_range
    roll
  end

  def run_new_users_only
    build_queues_new_users
    roll
  end

  def test_bug
    # @bar = ProgressBar.new(@selection.size)
    build_range(1, 10)
    # build_queues_new_users
    @selection.each do |user, visitor_count|
      puts "#{user}"
      # @bar.increment!
    end
  end

end
