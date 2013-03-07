require 'rubygems'
require 'progress_bar'

class Harvester
  attr_reader :type
  attr_accessor :type

  def initialize(args)
    @browser = args[ :browser]
    @database = args[ :database]
    @user = args[ :user_stats]
    @settings = args[ :settings]
  end

  def user
    @user
  end

  def run
    # run code
  end

  def body
    @browser.body
  end

  def min_match_percentage
    @settings[:min_percent].to_i
  end

  def min_age
    @settings[:min_age].to_i
  end

  def max_age
    @settings[:max_age].to_i
  end

  def max_distance
    @settings[:distance].to_i
  end

  def scrape_from_user
    self.leftbar_scrape
    self.similar_user_scrape
  end

  def meets_preferences?
    ((@user.match_percentage >= min_match_percentage) &&
      (@user.relative_distance <= max_distance) &&
      (@user.age <= max_age) &&
      (@user.age >= min_age))
  end

  def leftbar_scrape
    # @browser.go_to(url)
    array = body.scan(/href="\/profile\/([\w\d]+)\?leftbar\_match\=1"/)
    array.each { |user| @database.add_user(:username => user[0], :state => @user.state) }
  end

  def similar_user_scrape
    # @found = Array.new
    # @database.log(match)
    # @browser.go_to("http://www.okcupid.com/profile/#{match}")
    if meets_preferences?
      users = body.scan(/href="\/profile\/([\w\d]+)\?cf\=profile\_similar"/)
      users.each do |user|
          if @user.gender == "F"
            @database.add_user(:username => user[0], :state => @user.state)
            @database.set_state(:username => user[0], :state => @user.state)
            @database.set_gender(:username => user[0], :gender => @user.gender)
            @database.set_distance(:username => user[0], :distance => @user.relative_distance)
          end
      end
    end
  end

  def increment_visitor_counter(visitor)
    original      = @database.get_visitor_count(visitor)
    new_counter   = original + 1

    @database.set_visitor_counter(visitor, new_counter)
  end

  def visitors
    @browser.go_to("http://www.okcupid.com/visitors")
    @current_user       = @browser.current_user
    @visitors_page      = @current_user.parser.xpath("//div[@id='main_column']").to_html
    @details    = @visitors_page.scan(/>([\w\d]+).+(\d{2}) \/ (F|M)\s\/\s(\w+)\s\/\s[\w\s]+.+"location".([\w\s]+)..([\w\s]+)/)


    @gender     = Hash.new(0)
    @age        = Hash.new(0)
    @sexuality  = Hash.new(0)
    @state      = Hash.new(0)
    @city       = Hash.new(0)

    @details.each do |user|
      handle              = user[0]
      age                 = user[1]
      gender              = user[2]
      sexuality           = user[3]
      city                = user[4]
      state               = user[5]
      @gender[handle]     = gender
      @state[handle]      = state
      @city[handle]       = city
      @state[handle]      = state
      @sexuality[handle]  = sexuality
      @age[handle]        = age
    end

    visitor_list   = @visitors_page.scan(/"usr-([\w\d]+)".+z\-index\:\s(\d\d\d)/)
    @count  = 0
    visitor_list.each do |visitor, zindex|

      @timestamp_block  = @current_user.parser.xpath("//div[@id='usr-#{visitor}-info']/p/script/text()").to_html
      @timestamp        = @timestamp_block.match(/(\d{10}), 'JOU/)[1].to_i
      @stored_timestamp = @database.get_visitor_timestamp(visitor).to_i

      unless @stored_timestamp == @timestamp
        @count += 1
        self.increment_visitor_counter(visitor)

        if @gender[visitor] == "M"
          @database.ignore_user(visitor)
          @database.set_gender(:username => visitor, :gender => "M")
        else
          @database.add_user(:username => visitor)
          @database.set_gender(:username => visitor, :gender => "F")
          @database.set_state(:username => visitor, :state => @state[visitor])
        end

      end

      @database.set_visitor_timestamp(visitor, @timestamp.to_i)

    end

    @count.to_i
  end

  def scrape_home_page
    @browser.go_to("http://www.okcupid.com/home?cf=logo")
    results = body.scan(/class="username".+\/profile\/([\d\w]+)\?cf=home_matches.+(\d{2})\s\/\s(F|M)\s\/\s([\w\s]+)\s\/\s[\w\s]+\s.+"location".([\w\s]+)..([\w\s]+)/)

    results.each do |user|
      handle      = user[0]
      age         = user[1]
      gender      = user[2]
      sexuality   = user[3]
      city        = user[4]
      state       = user[5]
      @database.add_user(:username => handle, :state => state)
      @database.set_gender(:username => handle, :gender => gender)
      # @database.set_age(:username => handle, :age => age)
      @database.set_state(:username => handle, :state => state)
      # @database.set_city(:username => handle, :city => city)
    end
  end
end
