require 'rubygems'
require 'progress_bar'

class Harvester
  attr_reader :type
  attr_accessor :type

  def initialize(args)
    @browser      = args[ :browser]
    @database     = args[ :database]
    @user         = args[ :profile_scraper]
    @settings     = args[ :settings]
    @verbose      = @settings.verbose
    @debug        = @settings.debug
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

  def current_user
    @browser.current_user
  end

  def verbose
    @verbose
  end

  def debug
    @debug
  end

  def min_match_percentage
    @settings.min_percent
  end

  def min_age
    @settings.min_age
  end

  def max_age
    @settings.max_age
  end

  def max_distance
    @settings.max_distance.to_i
  end

  def preferred_state
    @settings.preferred_state
  end

  def preferred_city
    @settings.preferred_city
  end

  def scrape_from_user
    self.leftbar_scrape
    self.similar_user_scrape
  end

  def distance_criteria_met?
    # puts "by state:     #{filter_by_state?}" if verbose
    # puts "Max dist:     #{max_distance}" if verbose
    # puts "Rel dist:     #{@user.relative_distance}" if verbose

    case @settings.distance_filter_type
    when "state"
      @user.state == preferred_state
    when "city"
      @user.city == preferred_city
    when "distance"
      @user.relative_distance <= max_distance
    end
  end

  def match_percent_criteria_met?
    (@user.match_percentage >= min_match_percentage || (@user.match_percentage == 0 && @user.friend_percentage == 0))
  end

  def age_criteria_met?
    @user.age.between?(min_age, max_age)
  end


  def meets_preferences?
    puts "Match met:    #{match_percent_criteria_met?}" if verbose
    puts "Distance met: #{distance_criteria_met?}" if verbose
    puts "Age met:      #{age_criteria_met?}" if verbose
    match_percent_criteria_met? &&
      distance_criteria_met? &&
      age_criteria_met?
  end

  def leftbar_scrape
    puts "Scraping: leftbar" if verbose
    # @browser.go_to(url)
    array = body.scan(/\/([\w\d_-]+)\?leftbar_match/)
    array.each { |user| @database.add_user(user[0]) }
  end

  def similar_user_scrape
    puts "Scraping: similar users" if verbose
    # @found = Array.new
    # @database.log(match)
    # @browser.go_to("http://www.okcupid.com/profile/#{match}")
    if meets_preferences?
      users = body.scan(/\/([\w\d _-]+)....profile_similar/)
      users = users.to_set
      users.each do |user|
        if @user.gender == @settings.gender
          @database.add_user(user[0])
          @database.set_state(:username => user[0], :state => @user.state)
          @database.set_gender(:username => user[0], :gender => @user.gender)
          @database.set_distance(:username => user[0], :distance => @user.relative_distance)
        end
      end
    else
      puts "Not scraped: #{@user.handle}" if verbose
    end
  end

  def increment_visitor_counter(visitor)
    original      = @database.get_visitor_count(visitor)
    new_counter   = original + 1

    @database.set_visitor_counter(visitor, new_counter)
  end

  def increment_message_counter(user)
    original = @database.get_received_messages_count(user)
    new_counter = original + 1

    @database.set_received_messages_count(user, new_counter)
  end

  def visitors
    @browser.go_to("http://www.okcupid.com/visitors")
    @current_user       = @browser.current_user
    @visitors_page      = @current_user.parser.xpath("//div[@id='main_column']").to_html
    @details    = @visitors_page.scan(/>([\w\d]+).+(\d{2}) \/ (F|M)\s\/\s(\w+)\s\/\s[\w\s]+.+"location".([\w\s]+)..([\w\s]+)/)

    puts @visitors_page if debug
    wait = gets.chomp if debug

    @gender     = Hash.new("Q")
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

        puts visitor if verbose

        puts "Scraped gender: #{@gender[visitor]}" if verbose
        puts "Setting gender: #{@settings.gender}" if verbose


        @database.add_user(visitor)

        @database.ignore_user(visitor) unless @gender[visitor] == @settings.gender

        @database.set_gender(:username => visitor, :gender => @gender[visitor])
        @database.set_state(:username => visitor, :state => @state[visitor])

      increment_visitor_counter(visitor)
      end

      @database.set_visitor_timestamp(visitor, @timestamp.to_i)
    end

    @count.to_i
  end

  def log_this(item)
    File.open("scraped.log", "w") do |f|
      f.write(item)
    end
    wait = gets.chomp
  end

  def test_more_matches
    Exceptional.rescue do
      5.times do
        @browser.go_to("http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=11&count=10&ajax_load=1")
        parsed = JSON.parse(@browser.current_user.content).to_hash
        html = parsed["html"]
        @details = html.scan(/<div class="match_row match_row_alt\d clearfix " id="usr-([\w\d_-]+)">/)
        html_doc = Nokogiri::HTML(html)
        # @database.open

        @gender     = Hash.new("Q")
        @age        = Hash.new(0)
        # @sexuality  = Hash.new(0)
        @state      = Hash.new(0)
        @city       = Hash.new(0)

        @details.each do |user|
          result = html_doc.xpath("//div[@id='usr-#{user[0]}']/div[1]/div[1]/p[1]").to_s

          age = "#{result.match(/(\d{2})/)}".to_i
          gender = "#{result.match(/(M|F)</)[1]}"
          result = html_doc.xpath("//div[@id='usr-#{user[0]}']/div[1]/div[1]/p[2]").to_s
          # puts city, state
          username = user[0].to_s
          @database.add_user(username)
          @database.set_gender(:username => username, :gender => gender)
          @database.set_age(username, age)
          begin
            city = /location.>(.+),\s(.+)</.match(result)[1].to_s
            state = /location.>(.+),\s(.+)</.match(result)[2].to_s
            @database.set_city(username, city)
            @database.set_state(:username => username, :state => state)
          rescue
          end
        end

        # @database.close
        sleep 2
      end
    end
  end

  def scrape_matches_page(url="http://www.okcupid.com/match")
    @browser.go_to(url)
    @current_user       = @browser.current_user
    @matches_page       = @current_user.parser.xpath("//div[@id='match_results']").to_html
    @details    = @matches_page.scan(/\/([\w\s_-]+)\?cf=regular".+<p class="aso" style="display:"> (\d{2})<span>&nbsp;\/&nbsp;<\/span> (M|F)<span>&nbsp;\/&nbsp;<\/span>(\w)+<span>&nbsp;\/&nbsp;<\/span>\w+ <\/p> <p class="location">([\w\s-]+), ([\w\s]+)<\/p>/)


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

    matches_list   = @matches_page.scan(/"usr-([\w\d]+)"/)
    @count  = 0
    matches_list.each do |username, zindex|

      @database.add_user(username)
      @database.set_gender(:username => username, :gender => "F")
      @database.set_age(username, @age[username])
      @database.set_city(username, @city[username])
      @database.set_sexuality(username, @sexuality[username])
      @database.set_state(:username => username, :state => @state[username])

    end

  end

  def scrape_home_page
    puts "Scraping home page." if verbose
    @browser.go_to("http://www.okcupid.com/home?cf=logo")
    results = body.scan(/class="username".+\/profile\/([\d\w]+)\?cf=home_matches.+(\d{2})\s\/\s(F|M)\s\/\s([\w\s]+)\s\/\s[\w\s]+\s.+"location".([\w\s]+)..([\w\s]+)/)

    results.each do |user|
      handle      = user[0]
      age         = user[1]
      gender      = user[2]
      sexuality   = user[3]
      city        = user[4]
      state       = user[5]
      @database.add_user(handle)
      @database.set_gender(:username => handle, :gender => gender)
      # @database.set_age(:username => handle, :age => age)
      @database.set_state(:username => handle, :state => state)
      # @database.set_city(:username => handle, :city => city)
    end
  end

  def scrape_matches
    puts "Scraping matches" if verbose

    @browser.go_to("http://www.okcupid.com/match")
    results = body.scan(/\/([\w\d _-]+)....regular/)

    results.each do |user|
      @payload
    end

  end


  def scrape_activity_feed
    puts "Scraping activity feed." if verbose
    @browser.go_to("http://www.okcupid.com/home?cf=logo")
    results = body.scan(/\/profile\/([\w\d_-]+)\?cf=home_orbits.>.</)
    results.each do |user|
      handle = user[0]
      @database.add_user(handle)
    end
  end

  def scrape_inbox
    puts "Scraping inbox" if verbose
    items_per_page = 30

    # page_turner(
    #   :page_links => "<a href=.\/messages\?low=(\d+)&amp.folder.\d.>",
    #   :pre_var_url => "http://www.okcupid.com/messages?low=",
    #   :post_var_url => "&folder=1",
    #   :items_per_page => 30,
    #   :initial_page => "http://www.okcupid.com/messages",
    #   :scraper_object => @browser
    #   )


    @browser.go_to("http://www.okcupid.com/messages")

    all_lows    = body.scan(/<a href=.\/messages\?low=(\d+)&amp.folder.\d.>/)
    highest     = 0

    all_lows.each do |item|
      highest   = item[0].to_i if item[0].to_i > highest.to_i
    end

    total       = highest
    puts "Total messages: #{total}" if verbose
    @bar         = ProgressBar.new(total, :counter) unless verbose
    @bar.increment! 1 unless verbose
    do_page_action("http://www.okcupid.com/messages")
    low         = items_per_page + 1

    until low >= total
      @bar.increment! 30 unless verbose
      # do_page_action
      low += items_per_page
      @browser.go_to("http://www.okcupid.com/messages?low=#{low}&folder=1")
      track_msg_dates
      sleep 2
    end

  end

  def page_turner(args)
    page_links      = Regexp.quote(args[ :page_links].to_s)
    pre_var_url     = args[ :pre_var_url].to_s
    post_var_url    = args[ :post_var_url].to_s
    @ITEMS_PER_PAGE  = args[ :items_per_page].to_i
    initial_page    = args[ :initial_page].to_s
    @scraper        = args[ :scraper_object]
    @last_page       = 0


    @scraper.go_to(initial_page)

    page_numbers = body.scan(/#{Regexp.quote(page_links)}/)

    puts page_numbers

    page_numbers.each do |page|
      page_number = page[0].to_i
      @last_page = page_number if page_number > @last_page.to_i
    end

    puts @last_page

    @page = @ITEMS_PER_PAGE + 1

    do_page_action(initial_page)


    until @page >= @last_page
      do_page_action("#{pre_var_url}#{@page}#{post_var_url}")
      @page += @ITEMS_PER_PAGE
    end

  end


  def do_page_action(url)
    puts "","Scraping: #{url}" if verbose
    @browser.go_to(url)
    track_msg_dates
    sleep 2
  end

  def track_msg_dates
    message_list = body.scan(/"message_(\d+)"/)

    message_list.each do |message_id|

      message_id      = message_id[0]
      msg_block       = current_user.parser.xpath("//li[@id='message_#{message_id}']").to_html
      sender          = /\/([\w\d_-]+)\?cf=messages/.match(msg_block)[1]
      timestamp_block = current_user.parser.xpath("//li[@id='message_#{message_id.to_s}']/span/script/text()").to_html
      timestamp       = timestamp_block.match(/(\d{10}), 'MAI/)[1].to_i
      sender          = sender.to_s
      stored_time     = @database.get_last_received_message_date(sender)

      @database.ignore_user(sender)

      unless stored_time == timestamp
        increment_message_counter(sender)
        @database.set_last_received_message_date(sender, timestamp)
      end

    end
  end

end
