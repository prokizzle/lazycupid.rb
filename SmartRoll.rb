require './Blocklist'

class SmartRoll
  attr_reader :max, :delete, :mode, :days
  attr_accessor :max, :delete, :mode, :days

  def initialize(args)
    @db = args[ :database]
    @blocklist = args[ :blocklist]
    @harvester = args[ :harvester]
    @user = args[ :user_stats]
    @browser = args[ :browser]
    @display = args[ :gui]
    @max = args.fetch(:max_visists, 0)
    @profiles = Hash.new(0)
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
      (self.gender(user)=='M')
    rescue
      false
    end
  end

  def is_female(user)
    (self.gender(user)=='F')
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
    unix_date = @db.get_my_last_visit_date(match)
    ((Time.now.to_i - unix_date)/86400).round
  end

  def build_queues(mode)
    puts "Building queues"
    # if mode == "v"
      # @selection = select_by_last_visit_date(@days)
    # elsif mode == "c"
      @selection = select_by_visit_count(@max)
      @bar = ProgressBar.new(@selection.size)
    # else
      # @selection = overkill(@max)
    # end

    @selection.each do |user, visits|
      if @blocklist.is_ignored(user)
        @selection.delete(user)
        @bar.increment!
        # puts "#{user} is blocked. Removing."
      elsif (relative_last_visit(user) < 2)
        @selection.delete(user)
        @bar.increment!
        # puts "#{user} was visited recently. Removing."
      elsif (is_male(user))
        # puts "#{user} is not what you're looking for. Ignoring."
        @selection.delete(user)
        @db.ignore_user(user)
        @bar.increment!
      else
      @bar.increment!
      end
    end
    puts "#{@total} users queued up."
  end

  def autodiscover_new_users
    @harvester.scrape_from_user
  end

  def user_ob_debug
    begin
    test = [@user.gender, @user.handle, @user.match_percentage, @user.city, @user.state]
    rescue
    puts @browser.body
    user = gets.chomp
    end
  end

  def visit_user(user)
    mode = "smart"
    @browser.go_to("http://www.okcupid.com/profile/#{user}/")

     unless @browser.account_deleted
       self.user_ob_debug
       # @db.log(@browser.scrape_user_name, @browser.scrape_match_percentage)
       @db.log2(@user)
       @display.output(@user, @mph, mode)
       self.autodiscover_new_users if @user.gender=="F"
     end
     if self.inactive_account
       self.remove_match(user)
       puts "*Invalid user* : #{user}"
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

     def roll
       begin
         @selection.each do |user, counts|
           self.visit_user(user)
           sleep 6
         end
       rescue SystemExit, Interrupt
       end
     end

     def run
       self.build_queues(@mode)
       self.roll
     end

     end
