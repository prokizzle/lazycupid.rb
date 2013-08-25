module LazyCupid
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
      @roll_list  = Array.new
      @roll_list  = reload
      @verbose    = @settings.verbose
      @debug      = @settings.debug
      @alt_reload = false
      @already_idle = true
      @already_rolling = false
    end

    def reload
      queue = build_user_list(@db.followup_query)
      # queue = build_user_list(@db.new_user_smart_query)
      # queue = queue.concat(build_user_list(@db.followup_query))
      roll_type  = "mixed"
      puts "#{queue.size} users queued."
      return queue
    end

    def build_user_list(results)
      array = Array.new
      unless results == {}
        results.each do |user|
          array.push(user["name"]) if user.has_key?("name")
          # puts user["name"] if debug
        end
      end
      # array
      result = array.to_set
      return result.to_a
    end
    
    def cache
      if @roll_list.empty?
        @roll_list = build_user_list(@db.followup_query)
      else
        @roll_list
      end
    end

    def next_user
      cache.shift.to_s
    end

    def autodiscover_new_users(user)
      @harvester.scrape_from_user(user) if @settings.autodiscover_on
    end

    def remove_match(user)
      @db.delete_user(user)
    end

    def check_visitors
      viz = @tracker.parse_visitors_page
      @total_visitors += viz
      @total_visits += @tally
      @tally = 0
      puts ""
    end

    def payload
      puts "Getting new matches..." unless verbose
      3.times do
        @tracker.test_more_matches
      end
      puts "Checking for new messages..." unless verbose
      @tracker.scrape_inbox
      # check_visitors
    end

    def pre_roll_actions
      # @console.progress(@roll_list.size)
      @tally = 0
      @total_visitors = 0
      @total_visits = 0
      @start_time = Time.now.to_i
      payload
      puts "","Running..." unless verbose
    end

    def added_from(username)
      @db.get_added_from(username)
    end

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

    def enemy_blocker(user)
      if user[:enemy_percentage] > user[:match_percentage]
        @db.ignore_user(user[:handle])
      end
    end



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
        puts "Inactive profile found: #{user}"
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
        @console.log(response, roll_type) if verbose
        @tally += 1
        # puts "Logging user #{response}"
        @db.log2(response)
        # @harvester.body = @user.body
        autodiscover_new_users(response) if response[:gender] == @settings.gender
      end
    end

    def roll
      current_user = next_user
      # puts "Waiting..."
      # wait = gets.chomp
      unless current_user == @db.login
        unless current_user == nil || current_user == ""
          puts "Visting #{current_user}." if debug
          puts "Rolling..." unless @already_rolling
          visit_user(current_user)
          @already_idle = false
          @already_rolling = true
        else
          puts "Idle..." unless @already_idle
          @already_idle = true
          @already_rolling = false
        end
      end
    end
  end
end
