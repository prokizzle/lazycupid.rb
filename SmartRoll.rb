require './DataManager'
require './AutoRoller'
require './Blocklist'

class SmartRoll
  attr_reader :max, :mph, :delete, :mode, :days
  attr_accessor :max, :mph, :delete, :mode, :days

  def initialize(args)
    @db = args[ :database]
    @blocklist = Blocklist.new(:database => @db)
    @roller = args[ :visitor]
    @mph = args.fetch(:mph, 600)
    @max = args.fetch(:max_visists, 0)
    @names = @db.data
    @last_visit = @db.last_visit_date
    @profiles = Hash.new("---nick")
    @delete = Hash.new(false)
    @ignore_list = @db.ignore
    @profiles = Hash.new("---nick")
    @now = Time.now.to_i
    @mode = "c"
    @days = 2
  end

  def overkill(min)
    @db.filter_by_visits(1000,min)
  end

  def mode
    @mode
  end

  def reload
    @names = @db.data
  end

  def names
    @db.data
  end

  def select_by_visit_count(max, min=0)
    @select = @db.filter_by_visits(max)
  end

  def select_by_last_visit_date(day_input=1)
    max = Time.now.to_i - days(day_input).to_i
    min = 0
    @select = @db.filter_by_dates(min, max)
  end

  def days(number)
    86400 * number.to_i
  end

  def relative_last_visit(match)
    unix_date = @db.get_last_visit_date(match)
    ((Time.now.to_i - unix_date)/86400).round
  end

  def build_queues(mode)

    if mode == "v"
      @selection = select_by_last_visit_date(@days)
    elsif mode == "c"
      @selection = select_by_visit_count(@max)
    else
      @selection = overkill(@max)
    end

    @selection.each do |user, visits|
      if @blocklist.is_ignored(user)
        @selection.delete(user)
        puts "#{user} is blocked. Removing."
      elsif (relative_last_visit(user) < 2)
        @selection.delete(user)
        puts "#{user} was visited recently. Removing."
      end
    end

    # puts @selection
    # construct array of usernames to visit
    @selection.each do |user, counts|
      if user != nil && user != "N/A"
        @profiles[user] = "http://www.okcupid.com/profile/#{user}/"
      end
    end
  end

  def delete_inactive_user(user)
    @delete[user] = true
  end

  def visit_user(url, user)
    @roller.roll_dice(url, "smart")
    if self.inactive_account
      self.remove_match(user)
    end
  end

  def inactive_account
    @roller.account_deleted
  end

  def remove_match(user)
    @db.delete_user(user)
  end

  def set_speed
    @roller.mph = @mph
  end

  def save
    @roller.save
  end

  def roll
    begin
      @profiles.each do |user, link|
        self.visit_user(link, user)
      end
    rescue SystemExit, Interrupt
    end
    self.save
  end

  def run
    self.build_queues(@mode)
    self.set_speed
    self.roll
  end

end
