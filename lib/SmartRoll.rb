class SmartRoll
  attr_reader :max, :delete, :mode, :days
  attr_accessor :max, :delete, :mode, :days

  def initialize(args)
    @db         = args[ :database]
    @blocklist  = args[ :blocklist]
    @harvester  = args[ :harvester]
    @user       = args[ :profile_scraper]
    @browser    = args[ :browser]
    @display    = args[ :gui]
    @profiles   = Hash.new(0)
    @settings   = args[ :settings]
    @days       = 2
    @stats      = Statistics.new
    @selection  = Array.new
    @verbose    = true #@settings[:verbose]
    @debug      = true #@settings[:debug]
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

  def build_range(min, max, mode)

    case mode
    when 1
      location_filter = @settings[:preferred_state].to_s
    else
      location_filter = @settings[:distance].to_i
    end

    @selection = @db.range_smart_query(
                  days_ago(@settings[:days_ago].to_i),
                  min,
                  max,
                  location_filter,
                  @settings[:min_age].to_i,
                  @settings[:max_age].to_i,
                  @settings[:min_percent].to_i,
                  "distance")
  end


  def autodiscover_new_users
    @harvester.scrape_from_user
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
    # @display.update_progress(@total_visits)
    @display.dashboard(@total_visits, @total_visitors, @start_time, @tally, @current_state)
    # puts "Ratio: #{(viz/@tally).to_f}"
    @event_time = Chronic.parse('5 minutes from now').to_i
    @tally = 0
    puts ""
  end

  def summary
    check_visitors
    puts ""
    puts "Results: "
    puts "Visited:  #{@total_visits} people"
    puts "Visitors: #{@total_visitors}"
    sleep 4
  end

  def pre_roll_actions
    @display.progress(@selection.size)
    @tally = 0
    @total_visitors = 0
    @total_visits = 0
    @start_time = Time.now.to_i
    check_visitors
  end

  def visit_user(user)
    @browser.go_to("http://www.okcupid.com/profile/#{user}/", user)
    if inactive_account
      remove_match(user)
    else
      user_ob_debug if debug
      @display.console_out(@user) if verbose
      @tally += 1
      @db.log2(@user)
      @current_state = @user.state
      autodiscover_new_users if @user.gender == "F"
    end
  end

  def roll
    begin
      # @bar = ProgressBar.new(@selection.size)
      pre_roll_actions
      @selection.each do |user, counts, state|
        visit_user(user)
        sleep 6
        check_visitors if unix_time >= event_time
      end
    rescue Interrupt
    end
    summary
  end

  def gender_fix(days)
    build_queue_no_gender(days)
    roll
  end

  def run_range(min, max)
    build_range(min, max, @settings[:filter_by_state].to_i)
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
