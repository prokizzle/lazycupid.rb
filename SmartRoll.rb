require './DataManager'
require './AutoRoller'

class SmartRoll
  attr_reader :max, :mph
  attr_accessor :max, :mph

  def initialize(db, roller, max=4, mph=400)
    @db = db
    @max = max
    @roller = roller
    @names = @db.data
    @profiles = Hash.new("---nick")
    @mph = mph
  end



  def select(max)
    @profiles = Hash.new("---nick")
    @select = @names.select {|user, visits| visits == @max }
  end

  def buildQueues

    # construct array of usernames to visit
    @selection = self.select(@max)
    @selection.each do |user, counts|
      if user != nil && user != "N/A"
        @profiles[user] = "http://www.okcupid.com/profile/#{user}/"
      end
    end
  end

  def run
    begin
      buildQueues
      @profiles.each do |user, link|
        @roller.rollDice(link, @mph, "smart")
      end
    rescue SystemExit, Interrupt
    end
    @roller.save
  end

end
