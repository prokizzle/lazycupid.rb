module LazyCupid

  # Queues users, visits users, ignores incompatible users
  # The brains of LazyCupid
  #
  class SmartRoll
    require 'cliutils'
    include CLIUtils::Messaging
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

      @last_query_time = Time.now.to_i
      @verbose    = $verbose
      @debug      = $debug

      @alt_reload = false
      @already_idle = true
      @already_delayed = false
      @already_rolling = false
      @tally = 0
      @total_visitors = 0
      @total_visits = 0
      @start_time = Time.now.to_i
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
          puts "Visting #{current_user}." if $debug
          if $verbose
            messenger.warn "Rolling..." unless @already_rolling
          end
          visit_user(current_user)
          @already_idle = false
          @already_rolling = true
          # return {user: obj, rolling: @already_rolling}
        else
          if $verbose
            messenger.warn "Idle..." unless @already_idle
          end
          @already_idle = true
          @already_rolling = false
          # return {rolling: @already_rolling}
        end
      end
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
          user = user.to_hash
          array.push(user[:name]) if user.has_key?(:name)
          # puts user["name"] if $debug
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
        unless too_many_queries?
          @already_delayed = false
          @roll_list = build_user_list(@db.followup_query)
          @last_query_time = Time.now.to_i
          if $verbose
            puts "#{@roll_list.size} users queued" unless @roll_list.empty?
          end
        else
          messenger.warn "Delaying query..." unless @already_delayed
          @already_delayed = true
        end
        return @roll_list
      else
        return @roll_list
      end
    end

    # Rate limiter for hitting the db for roll queries
    #
    # returns true if not enough time has passed since last queue query
    #
    def too_many_queries?
      Time.now.to_i - @last_query_time <= $roll_frequency.to_i*10
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
    def sexuality_filter(profile)
      case profile[:sexuality]
      when "Gay"
        @db.ignore_user(profile[:handle]) unless @settings.visit_gay == true
      when "Bisexual"
        @db.ignore_user(profile[:handle]) unless @settings.visit_bisexual == true
      when "Straight"
        @db.ignore_user(profile[:handle]) unless @settings.visit_straight == true
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
      unless result[:inactive]
        profile = Profile.parse(result)
      else
        profile[:inactive] = true
      end
      if profile[:inactive]
        puts "Inactive profile found: #{user}" if $verbose
        begin
          @db.set_inactive(user)
        rescue
          puts user
          Match.where(name: user).update(gender: Match.where(:name => user, :account => $login).first[:gender])
        end

      elsif profile[:gender] != "M" && profile[:gender] != "F"
        messenger.warn "* Straight person found * #{user}"
        # puts profile[:gender], profile[:intended_handle]
        # %x{echo #{profile} >> profile.txt}
        Match.where(:name => user).update(:sexuality => "Straight")
      else

        begin
          @db.ignore_user(profile[:handle]) if profile[:enemy_percentage] > profile[:match_percentage]
        rescue
        end
        puts "Name change: #{profile[:a_list_name_change]}" if $debug
        if profile[:a_list_name_change]
          @db.rename_alist_user(user, profile[:handle])
          messenger.info "A-list name change: #{user} is now #{profile[:handle]}"
        end
        # sexuality_filter(profile)
        @tally += 1
        # puts "Logging user #{profile}"
        @db.log2(profile)
        @console.log(profile) if $verbose
        # @harvester.body = @user.body
        autodiscover_new_users(profile) if profile[:gender] == $gender || profile[:gender] == $alt_gender
      end
    end


  end
end
