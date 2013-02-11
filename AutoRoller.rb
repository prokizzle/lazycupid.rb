require 'rubygems'

class AutoRoller

  attr_accessor :names, :speed, :current_user, :mph
  attr_reader :names, :speed, :current_user, :mph

  def initialize(database, browser, display, mph=100)
    @mph = mph
    @GET_LUCKY_URL = "http://www.okcupid.com/getlucky?type=1"
    @max = 5000
    @database = database
    @browser = browser
    @display = display
    # speed
  end

  def init

  end

  def mph
    @mph
  end

  def speed
    3600/@mph
  end

  def names(u)
    @database.data(u)
  end


  def save
    @database.save
  end

  def quit
    @display.clear
    puts "User quit. Saving data..."
    # @database.save
    # puts "Done."
  end


  def roll_dice(url=@GET_LUCKY_URL, mode="normal")
    begin
      @browser.go_to(url)
      unless @browser.account_deleted
        @database.log(@browser.scrape_user_name, @browser.scrape_match_percentage)
        @display.output(@browser.scrape_user_name, @browser.scrape_match_percentage, @mph, mode)
      end
      sleep speed
    rescue
    end
  end

  def account_deleted
    @browser.account_deleted
  end

  def roller
    # i=1
    begin
      # while (i<=1000) do
      500.times do
        roll_dice
        # i+=1
        sleep speed
      end
    rescue SystemExit, Interrupt
      quit
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    @database.save
    puts "Done."
  end

  def run
    self.roller
  end

end
