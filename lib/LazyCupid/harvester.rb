module LazyCupid
  #
  # A class for gathering usernames to visit via various scraped portions of the site
  #
  class Harvester
    require 'cliutils'
    include CLIUtils::Messaging
    attr_reader :verbose, :debug, :min_match_percentage, :min_age, :max_age, :max_distance, :max_height, :min_height, :preferred_state, :preferred_city
    attr_accessor :type, :user, :body

    def initialize(args)
      @browser      = args[ :browser]
      @database     = args[ :database]
      # @user         = args[ :profile_scraper]
      @settings     = args[ :settings]
      @events       = args[ :events]
      # @verbose      = @settings.verbose
      # @debug        = @settings.debug

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
    def add_user(user)
      method_name = caller[0][/`.*'/].to_s.match(/`(.+)'/)[1]
      @database.add_user(username: user[:username], gender: user[:gender], added_from: method_name)
    end



    # Determines if user is within preferred distance
    #
    # @return [Boolean]
    #
    def distance_criteria_met?
      @user[:distance] <= max_distance
    end

    # Determines if your age is within their desired age range
    def age_range_criteria_met?
      # p @user[:age_range]
      in_range = (@user[:age_range][:min_age]..@user[:age_range][:max_age]).to_a.include? $my_age
      is_cougar = (@user[:age] - @user[:age_range][:min_age]) > 9
      return (in_range || is_cougar)
    end

    # Determines if user is within preferred match percentage range
    #
    # @return [Boolean]
    #
    def match_percent_criteria_met?
      (@user[:match_percentage] >= min_match_percentage || (@user[:match_percentage] == 0 && @user[:enemy_percentage] == 0))
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

    def conidtional_color_log(label, item)
      if item
        puts "#{label}:\t\t#{item}".green
      else
        puts "#{label}:\t\t#{item}".red
      end
    end

      # Determines if user meets preferred match requirements
      #
      # @return [Boolean]
      #
      def meets_preferences?
        if $verbose
          conidtional_color_log "Match met", match_percent_criteria_met?
          conidtional_color_log "Your Age met", age_range_criteria_met?
          conidtional_color_log "Distance met", distance_criteria_met?
          conidtional_color_log "Their Age met", age_criteria_met?
          conidtional_color_log "Height met", height_criteria_met?
          conidtional_color_log "Sexuality met", sexuality_criteria_met?
        end

        unless height_criteria_met?
          messenger.warn "Ignoring #{@user[:handle]} based on their height." if $verbose
          @database.ignore_user(@user[:handle])
        end

        match_percent_criteria_met? &&
          distance_criteria_met? &&
          age_criteria_met? &&
          sexuality_criteria_met? &&
          age_range_criteria_met?
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
          messenger.section "Scraping: leftbar" if $verbose
          array = @body.scan(/\/([\w\d_-]+)\?cf\=leftbar_match/)
          array.each { |user| @database.add_user(username: user.shift, gender: $gender, added_from: "leftbar") }
          messenger.section "Scraping: similar users" if $verbose
          similars = @body.scan(/\/([\w\d _-]+)....profile_similar/)
          similars = similars.to_set
          similars.each do |similar_user|
            similar_user = similar_user.shift
            if user_[:gender] == $gender || user_[:gender] == $alt_gender
              @database.add_user(username: similar_user, gender: user_[:gender], added_from: "similar_users", city: user_[:city], state: user_[:state])
            end
          end
        else
          messenger.error "Similar users not scraped: #{@user[:handle]}" if $verbose
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

          add_user(username: username, gender: gender, age: age, sexuality: sexuality, city: city, state: state)
          # Match.find_or_create(username: username, gender: gender, age: age, sexuality: sexuality, city: city, state: state, added_from: 'ajax_match_search')
        end

      end

      # Scrapes the OKCupid home page for users to add to database
      #
      def scrape_home_page
        puts "Scraping home page." if $verbose
        @browser.go_to("http://www.okcupid.com/home?cf=logo")
        results = body.scan(/class="username".+\/profile\/([\d\w]+)\?cf=home_matches.+(\d{2})\s\/\s(F|M)\s\/\s([\w\s]+)\s\/\s[\w\s]+\s.+"location".([\w\s]+)..([\w\s]+)/)

        results.each do |user|
          handle      = user.shift #user[0]
          age         = user.shift #user[1]
          gender      = user.shift #user[2]
          sexuality   = user.shift #user[3]
          city        = user.shift #user[4]
          state       = user.shift #user[5]
          add_user(username: handle, gender: gender, city: city, state: state)
          # @database.set_age(:username => handle, :age => age)
        end
      end
    end
  end
