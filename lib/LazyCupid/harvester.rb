module LazyCupid
  #
  # A class for gathering usernames to visit via various scraped portions of the site
  #
  class Harvester
    attr_reader :verbose, :debug, :min_match_percentage, :min_age, :max_age, :max_distance, :max_height, :min_height, :preferred_state, :preferred_city
    attr_accessor :type, :user, :body

    def initialize(args)
      @browser      = args[ :browser]
      @database     = args[ :database]
      # @user         = args[ :profile_scraper]
      @settings     = args[ :settings]
      @events       = args[ :events]
      @verbose      = @settings.verbose
      @debug        = @settings.debug

      @min_match_percentage = @settings.min_percent
      @min_age              = @settings.min_age
      @max_age              = @settings.max_age
      @max_distance         = @settings.max_distance.to_i
      @max_height           = @settings.max_height.to_f
      @min_height           = @settings.min_height.to_f
      @preferred_state      = @settings.preferred_state
      @preferred_city       = @settings.preferred_city
    end

    # def user
    #   @user
    # end

    def run
      # run code
    end

    def body
      @user[:body]
    end

    def current_user
      @browser.current_user
    end

    # Wrapper method to add a user to the database
    #
    # @param user [String] username of user to be added
    # @param gender [String] gender of user to be added
    #
    def add_user(user, gender)
      method_name = caller[0][/`.*'/].to_s.match(/`(.+)'/)[1]
      @database.add_user(user, gender, method_name)
    end



    # Determines if user is within preferred distance
    #
    # @return [Boolean]
    #
    def distance_criteria_met?
      @user[:distance] <= max_distance
    end

    # Determines if user is within preferred match percentage range
    #
    # @return [Boolean]
    #
    def match_percent_criteria_met?
      (@user[:match_percentage] >= min_match_percentage || (@user[:match_percentage] == 0 && @user[:friend_percentage] == 0))
    end

    # Determines if user meets preferred age requirements
    #
    # @return [Boolean]
    #
    def age_criteria_met?
      @user[:age].between?(min_age, max_age)
    end

    # Determines if user meets preferred height requirements
    #
    # @return [Boolean]
    #
    def height_criteria_met?
      (@user[:height].to_f >= min_height && @user[:height].to_f <= max_height) || @user[:height] == 0
    end

    # Determines if user meets preferred sexuality requirements
    #
    # @return [Boolean]
    #
    def sexuality_criteria_met?
      (@user[:sexuality] == "Gay" if @settings.visit_gay) ||
        (@user[:sexuality] == "Straight" if @settings.visit_straight) ||
        (@user[:sexuality] == "Bisexual" if @settings.visit_bisexual)
    end

    # Determines if user meets preferred match requirements
    #
    # @return [Boolean]
    #
    def meets_preferences?
      puts "Match met:        #{match_percent_criteria_met?}" if verbose
      puts "Distance met:     #{distance_criteria_met?}" if verbose
      puts "Age met:          #{age_criteria_met?}" if verbose
      puts "Height met:       #{height_criteria_met?}" if verbose
      puts "Sexuality met:    #{sexuality_criteria_met?}" if verbose

      unless height_criteria_met?
        puts "Ignoring #{@user[:handle]} based on their height." if verbose
        @database.ignore_user(@user[:handle])
      end

      match_percent_criteria_met? &&
        distance_criteria_met? &&
        age_criteria_met? &&
        sexuality_criteria_met?
    end

    # Scrapes new matches from a user profile page and adds them to the database
    #
    # @param user_body [Page object] A Mechanize Page object for a user's profile page
    #
    def scrape_from_user(user_body)
      @user = user_body
      # @found = Array.new
      # @database.log(match)
      if meets_preferences?
        user_ = user_body
        @body = user_[:body]
        puts "Scraping: leftbar" if verbose
        array = @body.scan(/\/([\w\d_-]+)\?leftbar_match/)
        array.each { |user| @database.add_user(user.shift, @settings.gender, "leftbar") }
        puts "Scraping: similar users" if verbose
        similars = @body.scan(/\/([\w\d _-]+)....profile_similar/)
        similars = similars.to_set
        similars.each do |similar_user|
          similar_user = similar_user.shift
          if user_[:gender] == @settings.gender
            @database.add_user(similar_user, user_[:gender], "similar_users")
            @database.set_state(:username => similar_user, :state => @user[:state])
            # @database.set_gender(:username => similar_user, :gender => @user[:gender])
            @database.set_distance(:username => similar_user, :distance => @user[:distance])
          end
        end
      else
        puts "Not scraped: #{@user[:handle]}" if verbose
      end


    end

    # Scrapes the matches page and adds new matches to the database
    #
    # @param url [String] url of matches page to scrape
    #
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
      matches_list.each do |username|

        add_user(username, gender)
        @database.set_gender(:username => username, :gender => @gender[username])
        @database.set_age(username, @age[username])
        @database.set_city(username, @city[username])
        @database.set_sexuality(username, @sexuality[username])
        @database.set_state(:username => username, :state => @state[username])
        #User.where(:name => username).update(gender: @gender[username], age: @age[username], city: @city[username], state: @state[username], sexuality: @sexuality[username])
      end

    end

    # Scrapes the OKCupid home page for users to add to database
    #
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
        add_user(handle, gender)
        @database.set_gender(:username => handle, :gender => gender)
        # @database.set_age(:username => handle, :age => age)
        @database.set_state(:username => handle, :state => state)
        # @database.set_city(:username => handle, :city => city)
      end
    end
  end
end
