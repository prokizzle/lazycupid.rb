# TBD - Due to changes in OKCupid, this class is now useless
# This was the first class of the project, the starting point from which everything
# grew. So long, auto-roller.
class AutoRoller

  attr_accessor :speed, :current_user, :mph
  attr_reader :speed, :current_user, :mph

  def initialize(args)
    @mph            = args.fetch(:mph, 100)
    @GET_LUCKY_URL  = "http://www.okcupid.com/getlucky?type=1"
    @max            = 5000
    @user           = args[ :user_stats]
    @database       = args[ :database]
    @browser        = args[ :browser]
    @display        = args[ :gui]
    @mph            = 400
  end

  def init

  end

  def mph
    @mph
  end

  def speed
    3600 / @mph
  end

  def quit
    @display.clear
  end


  def roll_dice(url=@GET_LUCKY_URL, mode="normal")
      @browser.go_to(url)
      unless @browser.account_deleted
        @database.log(@browser.scrape_user_name, @browser.scrape_match_percentage)
        @display.output(@browser.scrape_user_name, @browser.scrape_match_percentage, @mph, mode)
      end
      # sleep self.speed
  end

  def account_deleted
    @browser.account_deleted
  end

  def roller
    # i=1
    begin
      # while i <= 1000 do
      500.times do
        roll_dice
        # i += 1
        sleep speed
      end
    rescue SystemExit, Interrupt
      quit
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

  def run
    self.roller
  end

end
