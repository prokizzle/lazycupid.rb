module LazyCupid
  class Log
    def debug(args)
      puts args
    end
  end

  # Handler for API events
  # Each event from the OKCupid API is assigned a method, with actions based on event type
  #
  class APIEvents

    # if you come across an unknown API event, add it to attr_reader as a workaround
    attr_reader :orbit_vote, :verbose, :debug

    def initialize(args)
      log_errors = false
      @tracker = args[ :tracker]
      if log_errors
        @log   = args[ :logger]
      else
        @log        = Log.new
      end
      @api_events = Array.new
      @spotlight  = Hash.new
      @messages   = Hash.new
      @stalks     = Hash.new
      @settings   = args[:settings]

      # @g = Growl.new "localhost", "#{@tracker.account}"
      # @g.add_notification "lazy-cupid-notification"


    end

    # Sends events to proper methods
    #
    # @param event  [Hash]    event specific details related to API event
    # @param people [Hash]    user details for users related to API event
    # @param key    [Integer] unique identifier for event
    #
    def process(event, people, key)
      @event = event
      @key = key
      @api_event = Hash.new(event: @event, people: people, key:key)
      puts "Received event..." if $debug
      puts event if $debug
      unless @api_events.include? @event["server_seqid"]
        if @event["from"] == people["screenname"]
          puts "Processing unique event..." if $debug
          @api_events << @event["server_seqid"]
          @event.merge!(people)
          puts @event if $debug
          send(@event["type"])
        end
      end
    end

    # User readable time format
    #
    # @return [String]
    #
    def formatted_time
      "#{Time.now.hour}:#{Time.now.min}"
    end

    # Determines if event is valid for processing
    #
    # @return [Boolean]
    #
    def invalid_event
      @event["from"] == "0" || @people.nil? || @people == {} || @people.empty?
    end

    def orbit_profile_updated
    end

    # New mail notification
    #
    def msg_notify
      # unless Time.now.to_i - @last_call <= 1
      # p @event
      # key = "#{@event['server_gmt']}#{@event['from']}"
      # p key
      # unless @messages.has_key?(key)
      # puts "New message from #{@event["from"]}"
      # @tracker.register_message(@event["from"], @event["server_gmt"], @people["gender"])
      @tracker.scrape_inbox
      # end
      # @messages[key] = "#{@event['server_gmt']}#{@event['from']}"
      # @last_call = Time.now.to_i
      # end
    end

    def mutual_match
      puts "* New mutual match: #{@event["from"]} *"
    end

    # Returns a HTML formatted link for a given profile
    # @param profile [String] username for profile to display
    #
    # @return [String] formatted HTML link to profile
    #
    def html_link(profile)
      "<a href='http://www.okcupid.com/profile/#{profile}'>profile</a>"
    end

    # Probably somebody chose you
    #
    def looks_vote
      @log.debug "looks_vote: #{@event["from"]}"
    end

    # New instant message
    # Currently not working
    #
    def im
      # unless @events_hash.has_key(this_event_time)
      puts "New IM from #{@event["from"]}" #unless @event["server_gmt"] == @gmt
      # @tracker.register_message(@event["screenname"], @event["server_gmt"])
      # end
      # @events_hash[this_event_time] = @event["screenname"]
      @event
    end

    # One of your favorites uploaded a new photo
    #
    def orbit_picture_upload
      #something
    end

    # OKCupid terminology for an incoming visit
    #
    def stalk
      @tracker.register_visit(@event)
    end

    # New featured user. These users jump to the top of your match searches
    # and all of them paid $2 for 20 minutes of exposure time. Might as well
    # add them to the db. ;)
    #
    # needs @people, @event, @spotlight, @tracker
    def new_spotlight_user
      handle_ = @people["screenname"]
      gmt_ = @event["server_gmt"]
      seqid = @event["server_seqid"]
      unless @spotlight.has_key?(seqid)
        # puts "New spotlight user: #{handle_} (#{@people["gender"]})" #if verbose
        @tracker.add_user(handle_, @people["gender"])
        @spotlight[seqid] = handle_
      end
      # print_event_info
    end

    # No idea what this does
    #
    def toolbar_trigger
      @log.debug "Toolbar trigger"
      # print_event_info
    end


    # Favorite user signed out
    #
    def orbit_user_signoff
      @log.debug "orbit_user_signoff: #{@event['screenname']}"
    end

    # Favorite user signed in
    #
    def orbit_user_signon
      @log.debug "orbit_user_signon: #{@event['screenname']}"
    end

    # One of your favorites answered a new question
    #
    def orbit_nth_question
      @log.debug "orbit_nth_question: #{@event['screenname']}"
    end



  end
end
