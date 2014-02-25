module LazyCupid

  # Watches the undocumented OKCupid API for instant events
  #
  class EventWatcher
    attr_reader :debug, :verbose

    def initialize(args)
      # puts "Initializing browser..."
      # @browser = Browser.new(:username => @username, :password => password)
      @browser      = args[:browser]
      @tracker      = args[:tracker]
      @log          = args[:logger]
      @settings     = args[:settings]

      @api          = APIEvents.new(tracker: @tracker, logger: @log, settings: @settings)

      @spotlight    = Hash.new
      @messages     = Hash.new
      @stalks       = Hash.new
      @looks_vote   = Hash.new
      @new_events   = Array.new
      @new_people   = Array.new
      @people_hash  = Hash.new
      @hash         = Hash.new { |hash, key| hash[key] = 0 }
      @events_hash  = Hash.new { |hash, key| hash[key] = 0 }
      @instant      = (1..4).to_a
    end

    # Returns the JSON responses from API calls
    #
    def long_poll_result
      response = async_response(api_url)
      return response[:body]
    end

    # Wrapper for browser requests
    # Generates unique request ids and returns only when full requests are received
    #
    # @return [Hash] objects of the browser request
    #
    def async_response(url)
      result = Hash.new { |hash, key| hash[key] = 0 }
      request_id = Time.now.to_i
      @browser.send_request(url, request_id)
      until result[:ready] == true
        result = @browser.get_request(request_id)
      end
      return result
    end

    # Wrapper for browser login method
    #
    def login
      @browser.login
    end

    # Wrapper for browser logout method
    #
    def logout
      @browser.logout
    end

    # Generates sequential URLs for API long polls
    # Okcupid uses 1 through 4 for prefixes of api polls
    # This method returns the next properly ordered prefixed url for polling
    #
    # @return [String] url to be used for long polling
    #
    def api_url
      @instant = (1..4).to_a if @instant.empty?
      i = @instant.shift
      return "http://#{i}-instant.okcupid.com/instantevents?random=#{rand}&server_gmt=#{Time.now.to_i}"
    end

    # Returns the server time for the most recent event received
    #
    # @return [Integer] server time for last event in Epoch format
    #
    def this_event_time
      @event["server_gmt"].to_i
    end

    # Parses the long poll result for JSON data
    #
    # @return [Hash] JSON object containing data
    def content
      (/(\{.+\})/.match(long_poll_result)[1])
    end

    # JSON formatted long poll result, removing escaped quotes
    #
    # @return [Hash] JSON object for long poll response data
    #
    def poll_response
      begin
        return JSON.parse(content.gsub('\"', '\'')).to_hash
      rescue JSON::ParserError
        return content
      end
    end

    # Processes the JSON object, parsing out multiple events received and associated users
    # Separates the users assigned to each event, and sends to the api_events class for
    # handling based on event types
    #
    def check_events
      temp              = poll_response
      index             = 0
      puts temp if $debug
      # begin
        if temp.has_key?("people")
          temp["people"].each do |user|
            unless @people_hash.has_key?(user["screenname"])
              @people_hash[user["screenname"]] = user
            end
          end
        end
        unless temp == {}
          # begin
            temp["events"].each do |event|
              key = "#{event['server_seqid']}#{event['type']}"
              unless @hash[key] == event["server_gmt"]
                # puts event
                @api.process(event, @people_hash[event['from']]||nil, key)
                @hash[key] = event["server_gmt"]
              end

            end
          # rescue
            # puts "*****"
            #@log.debug temp["events"]
            # puts "*****"
            # puts temp
          # end
        end
      # rescue Exception => e
        # puts e.message, e.backtrace
      # end

    end

    # The number of unread messages
    #
    # @return [Integer] number of unread messages
    #
    def new_mail
      poll_response['num_unread'].to_i
    end
  end
end
