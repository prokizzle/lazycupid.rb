class SmartRoll
  attr_reader :max, :delete, :mode, :days
  attr_accessor :max, :delete, :mode, :days

  def initialize(args)
    @db         = args[ :database]
    @blocklist  = args[ :blocklist]
    @harvester  = args[ :harvester]
    @user       = args[ :user_stats]
    @browser    = args[ :browser]
    @display    = args[ :gui]
    @profiles   = Hash.new(0)
    @settings   = args[ :settings]
    @days       = 2
    @stats      = Statistics.new
  end

  def sexuality(user)
    result = @database.get_sexuality(user)
    result[0][0].to_s
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

  def select_by_visit_count(max, min=0)
    @select = @db.filter_by_visits(max)
  end

  def query_for_users(num, counts)
    @select = @db.better_smart_query(days_ago(num), counts)
  end

  def build_new
    @selection = @db.better_smart_query2
  end

  def select_by_last_visit_date(day_input=1)
    max = Time.now.to_i - days(day_input).to_i
    min = 0
    @select = @db.filter_by_dates(min, max)
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

  def build_range(min, max)
    @selection = @db.range_smart_query(
                  days_ago(@settings[:days_ago].to_i),
                  min,
                  max)
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

  def visit_user(user)
    @browser.go_to("http://www.okcupid.com/profile/#{user}/")
    if inactive_account
      remove_match(user)
    else
      user_ob_debug
      @tally += 1
      @db.log2(@user)
      autodiscover_new_users if @user.gender == "F"
    end
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

  def pre_roll_actions
    @display.progress(@selection.size)
    @tally = 0
    @total_visitors =0
    @total_visits =0
    @start_time = Time.now.to_i
    check_visitors
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
    @display.update_progress(@total_visits)
    @display.dashboard(stats)
    # puts "Ratio: #{(viz/@tally).to_f}"
    @event_time = Chronic.parse('5 minutes from now').to_i
    @tally = 0
  end

  def summary
    check_visitors
    puts "Results: "
    puts "Visited:  #{@total_visits} people"
    puts "Visitors: #{@total_visitors}"
    sleep 4
  end

  def roll
    # @bar = ProgressBar.new(@selection.size)
    pre_roll_actions
      @selection.reverse_each do |user, counts, state|
        visit_user(user)
        sleep 6
        check_visitors if unix_time >= event_time
      end
    summary
  end

  def gender_fix(days)
    build_queue_no_gender(days)
    roll
  end

  def run2
    build_new
    roll
  end

  def run_range(min, max)
    build_range(min, max)
    roll
  end

  def run_new_users_only
    build_queues_new_users
    roll
  end

end
