require 'rubygems'

#
# A class for gathering usernames to visit via various scraped portions of the site
#
class Harvester
  attr_reader :type, :user
  attr_accessor :type, :user, :body

  def initialize(args)
    @browser      = args[ :browser]
    @database     = args[ :database]
    @user         = args[ :profile_scraper]
    @settings     = args[ :settings]
    @events       = args[ :events]
    @verbose      = @settings.verbose
    @debug        = @settings.debug
  end

  # def user
  #   @user
  # end

  def run
    # run code
  end

  def body
    @user.body
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

  def max_height
    @settings.max_height.to_f
  end

  def min_height
    @settings.min_height.to_f
  end

  def preferred_state
    @settings.preferred_state
  end

  def preferred_city
    @settings.preferred_city
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

  def height_criteria_met?
    @user.height.to_f >= min_height && @user.height.to_f <= max_height
  end


  def meets_preferences?
    puts "Match met:    #{match_percent_criteria_met?}" if verbose
    puts "Distance met: #{distance_criteria_met?}" if verbose
    puts "Age met:      #{age_criteria_met?}" if verbose
    puts "Height met:   #{height_criteria_met?}" if verbose

    unless height_criteria_met?
      puts "Ignoring #{@user.handle} based on their height." if verbose
      @database.ignore_user(@user.handle)
    end

    match_percent_criteria_met? &&
      distance_criteria_met? &&
      age_criteria_met?
  end

  def scrape_from_user(user_body)
    # @found = Array.new
    # @database.log(match)
    if meets_preferences?
      user_ = user_body
      @body = user_[:body]
      puts "Scraping: leftbar" if verbose
      array = @body.scan(/\/([\w\d_-]+)\?leftbar_match/)
      array.each { |user| @database.add_user(user.shift, @settings.gender) }
      puts "Scraping: similar users" if verbose
      similars = @body.scan(/\/([\w\d _-]+)....profile_similar/)
      similars = similars.to_set
      similars.each do |similar_user|
        similar_user = similar_user.shift
        if user_[:gender] == @settings.gender
          @database.add_user(similar_user, user_[:gender])
          @database.set_state(:username => similar_user, :state => @user.state)
          # @database.set_gender(:username => similar_user, :gender => @user.gender)
          @database.set_distance(:username => similar_user, :distance => @user.relative_distance)
        end
      end
    else
      puts "Not scraped: #{@user.handle}" if verbose
    end


  end

  def location_array(location)
    result    = location.scan(/,/)
    if result.size == 2
      city    = location.match(/(.+), (.+), (.+)/)[1]
      state   = location.match(/(.+), (.+), (.+)/)[2]
      country = location.match(/(.+), (.+), (.+)/)[3]
    elsif result.size == 1
      city    = location.match(/(.+), (.+)/)[1]
      state   = location.match(/(.+), (.+)/)[2]
    end
    {:city => city, :state => state}
  end


  def log_this(item)
    File.open("scraped.log", "w") do |f|
      f.write(item)
    end
    wait = gets.chomp
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

end
