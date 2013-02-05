require './DataManager'
require './AutoRoller'

class SmartRoll
  attr_reader :max, :mph, :delete
  attr_accessor :max, :mph, :delete

  def initialize(db, roller, max=4, mph=600)
    @db = db
    @max = max
    @roller = roller
    @names = @db.data
    @profiles = Hash.new("---nick")
    @mph = mph
    @delete = Hash.new(false)
    @ignore_list = @db.ignore
  end



  def select(max)
    @profiles = Hash.new("---nick")
    @select = @names.select {|user, visits| visits <= @max}
  end

  def build_queues

    # construct array of usernames to visit
    @selection = self.select(@max)
    @selection.each do |user, counts|
      if user != nil && user != "N/A"
        # unless (@ignore_list[user])
        puts @ignore_list[user]
          @profiles[user] = "http://www.okcupid.com/profile/#{user}/"
        # end
      end
    end
  end

  def delete_inactive_user(user)
    @delete[user] = true
  end

  def run
    begin
      build_queues
      @roller.mph = @mph
      @profiles.each do |user, link|
        # puts link
        @roller.roll_dice(link, "smart")
        if @roller.account_deleted
          @db.remove_match(user)
        end
      end
    rescue SystemExit, Interrupt
    end
    @roller.save
  end

end
