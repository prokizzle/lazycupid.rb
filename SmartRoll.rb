require './DataManager'
require './AutoRoller'

class SmartRoll
  attr_reader :max, :mph, :delete, :mode, :days
  attr_accessor :max, :mph, :delete, :mode, :days

  def initialize(args)
    @db = args[ :database]
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
    self.reload
    @names.select {|user, visits| visits.to_i >= @max.to_i}
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

  def select_by_visit_count(max)
    self.reload
    @select = names.select {|user, visits| visits <= @max}
    @select = @select.sort_by {|k,v| v.to_i}
    # @selection = self.select_by_visit_count(@max)
  end

  def select_by_last_visit_date(day_input=1)
    self.reload
    self.fix_blank_dates
    @select = @last_visit.select {|user, time| (@now - time.to_i) > days(day_input)}
    # puts @select
    # @selection = self.select_by_visit_count
  end

  def fix_blank_dates
    self.reload
    @last_visit.each do |user, time|
      if time == 0
        @last_visit[user] = @now
      end
    end
  end

  def days(number)
    86400 * number.to_i
  end

  def build_queues(mode)

    if mode == "v"
      @selection = select_by_last_visit_date(@days)
    elsif mode == "c"
      @selection = select_by_visit_count(@max)
    else
      @selection = overkill(@max)
    end

    self.fix_blank_dates

    @selection.each do |user, visits|
      if @ignore_list.has_key?(user)
        @selection.delete(user)
      elsif (@now - @last_visit[user].to_i) < days(2)
        @selection.delete(user)
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
    @db.remove_match(user)
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
