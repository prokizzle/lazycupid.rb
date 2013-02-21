require './Blocklist'

class SmartRoll
  attr_reader :max, :mph, :delete, :mode, :days
  attr_accessor :max, :mph, :delete, :mode, :days

  def initialize(args)
    @db = args[ :database]
    @blocklist = args[ :blocklist]
    @harvester = args[ :harvester]
    @user = args[ :user_stats]
    # @blocklist = Blocklist.new(:database => @db)
    @roller = args[ :visitor]
    @mph = args.fetch(:mph, 600)
    @max = args.fetch(:max_visists, 0)
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

  # def remove_straight_men


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
    unix_date = @db.get_my_last_visit_date(match)
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
      # elsif (@user.sexuality == "Straight" && @user.gender == "M")
      #   puts "#{user} is not what you're looking for. Removing."
      #   @selection.delete(user)
      #   @db.delete_user(user)
      end
    end
  end

  def autodiscover_new_users
    @harvester.scrape_from_user
  end

  def visit_user(user)
    @roller.roll_dice("http://www.okcupid.com/profile/#{user}/", "smart")
    self.autodiscover_new_users
     if self.inactive_account
       self.remove_match(user)
       puts "*Invalid user* : #{user}"
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

     def roll
       begin
         @selection.each do |user, counts|
           self.visit_user(user)
           sleep (3600/600)
         end
       rescue SystemExit, Interrupt
       end
     end

     def run
       self.build_queues(@mode)
       self.set_speed
       self.roll
     end

     end
