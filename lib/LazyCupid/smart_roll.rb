module LazyCupid

  # Queues users, visits users, ignores incompatible users
  # The brains of LazyCupid
  #
  class SmartRoll
    attr_reader :debug, :verbose, :alt_reload
    attr_accessor :alt_reload

    def initialize(args)
      @db         = args[:database]
      @blocklist  = args[:blocklist]
      @harvester  = args[:harvester]
      # @user       = args[:profile_scraper]
      @browser    = args[:browser]
      @settings   = args[:settings]
      @console    = args[:gui]
      @tracker    = args[:tracker]
      @roll_list  = {}
      @roll_list  = reload
      @verbose    = @settings.verbose
      @debug      = @settings.debug
      @alt_reload = false
      @already_idle = true
      @already_rolling = false
    end

    public
    # Performs one single visit to a valid user
    # Use this method in a loop or scheduler for continuous visiting
    #
    def roll
      current_user = next_user
      # puts "Waiting..."
      # wait = gets.chomp
      unless current_user == @db.login
        unless current_user.nil? || current_user == ""
          puts "Visting #{current_user}." if debug
          puts "Rolling..." unless @already_rolling
          visit_user(current_user)
          @already_idle = false
          @already_rolling = true
          # return {user: obj, rolling: @already_rolling}
        else
          puts "Idle..." unless @already_idle
          @already_idle = true
          @already_rolling = false
          # return {rolling: @already_rolling}
        end
      end
    end

    # Sets up pre-roll variables, runs actions before first roll
    #
    def pre_roll_actions
      # @console.progress(@roll_list.size)
      @tally = 0
      @total_visitors = 0
      @total_visits = 0
      @start_time = Time.now.to_i
      payload
      puts "","Running..." #unless verbose
    end

    private

    # Fills the queue back up with users to visit
    # @return [Array] array of hashes of users to visit
    #
    def reload
      queue = build_user_list(@db.followup_query)
      puts "#{queue.size} users queued." unless queue.empty?
      return queue
    end

    # Removes duplicate users, adds valid entries to an array
    #
    def build_user_list(results)
      array = Array.new
      unless results == {}
        results.each do |user|
          array.push(user["name"]) if user.has_key?("name")
          # puts user["name"] if debug
        end
      end
      # array
      return array.to_set.to_a
    end
    
    # Wrapper array for user queue
    # Auto reloads queue if empty
    # @return [Array]
    #
    def cache
      if @roll_list.empty?
        @roll_list = build_user_list(@db.followup_query)
        puts "#{@roll_list.size} users queued" unless @roll_list.empty?
        return @roll_list
      else
        return @roll_list
      end
    end

    # Returns the next user from the queue, removes the user from the queue
    # in the process
    # @return [Hash] user details
    #
    def next_user
      cache.shift.to_s
    end

    # Wrapper method for Harvester's profile scraper
    #
    def autodiscover_new_users(user)
      @harvester.scrape_from_user(user) if @settings.autodiscover_on
    end

    # Wrapper method for Database class delete user
    #
    def remove_match(user)
      @db.delete_user(user)
    end

    # TBD: Wrapper method for EventTracker's visitor page scraper
    #
    def check_visitors
      viz = @tracker.parse_visitors_page
      @total_visitors += viz
      @total_visits += @tally
      @tally = 0
      puts ""
    end

    # Actions to be executed on app launch
    #
    def payload
      puts "Getting new matches..." unless verbose
      3.times do
        @tracker.test_more_matches
      end
      puts "Checking for new messages..." unless verbose
      @tracker.scrape_inbox
      # check_visitors
    end

    # Determines which method added the user to the database
    # @param [username] [String] username for user to query
    # @return [String] method that added user to db
    #
    def added_from(username)
      @db.get_added_from(username)
    end

    # Ignores user based on sexuality preferences
    # @param [user]       [String] match's username
    # @param [sexuality]  [String] sexuality of match
    #
    def sexuality_filter(user, sexuality)
      case sexuality
      when "Gay"
        @db.ignore_user(user) unless @settings.visit_gay == true
      when "Bisexual"
        @db.ignore_user(user) unless @settings.visit_bisexual == true
      when "Straight"
        @db.ignore_user(user) unless @settings.visit_straight == true
      end
    end

    # Ignores user if their enemy percentage is higher than their match percentage
    # @param [user] [String] username of user to ignore
    #
    def enemy_blocker(user)
      if user[:enemy_percentage] > user[:match_percentage]
        @db.ignore_user(user[:handle])
      end
    end


    # Main control flow for visiting a user
    # @param [user] [String] username to visit
    #
    def visit_user(user, roll_type="NA")
      result = Hash.new { |hash, key| hash[key] = 0 }
      request_id = Time.now.to_i
      @browser.send_request("http://www.okcupid.com/profile/#{user}", request_id)
      until result[:ready] == true
        result = @browser.get_request(request_id)
        # p result
      end
      @browser.delete_response(request_id)
      response = Profile.parse(result)
      # puts response[:handle], response[:a_list_name_change], response[:inactive]
      if response[:inactive]
        puts "Inactive profile found: #{user}" if verbose
        # @db.ignore_user(user)
        @db.set_inactive(user)

      else

        begin
          @db.ignore_user(response[:handle]) if response[:enemy_percentage] > response[:match_percentage]
        rescue
        end
        puts "Name change: #{response[:a_list_name_change]}" if debug
        if response[:a_list_name_change]
          @db.rename_alist_user(user, response[:handle])
          puts "(SR) A-list name change: #{user} is now #{response[:handle]}"
        end
        # puts response
        sexuality_filter(response[:handle], response[:sexuality])
        @console.log(response) if verbose
        @tally += 1
        # puts "Logging user #{response}"
        @db.log2(response)
        # @harvester.body = @user.body
        autodiscover_new_users(response) if response[:gender] == @settings.gender
      end
    end


  end
end
