module LazyCupid
  class APIEvents

    # if you come across an unknown API event, add it to attr_reader as a workaround
    attr_reader :orbit_vote, :verbose, :debug

    def initialize(args)
      @tracker = args[ :tracker]
      @log     = args[ :logger]
      @spotlight  = Hash.new
      @messages   = Hash.new
      @stalks     = Hash.new
      @settings   = args[:settings]

      # @g = Growl.new "localhost", "#{@tracker.account}"
      # @g.add_notification "lazy-cupid-notification"


    end

    def process(event, people, key)
      @event = event
      @people = people
      @key = key
      @api_event = Hash.new(event: event, people: people, key:key)
      # print formatted_time
      unless invalid_event
        begin
          self.send(event["type"])
        rescue Exception => e
          puts "Error #{event}", e.message, e.backtrace
        end
      end
    end

    def formatted_time
      "#{Time.now.hour}:#{Time.now.min}"
    end

    def invalid_event
      @event["from"] == "0" || @people.nil? || @people == {}
    end

    def msg_notify
      # unless Time.now.to_i - @last_call <= 1
      p @event
      key = "#{@event['server_gmt']}#{@event['from']}"
      p key
      unless @messages.has_key?(key)
        # @g.notify "lazy-cupid-notification", "New Message", "#{@people['screenname']}" if @settings.growl_new_mail
        puts "New message from #{@event["from"]}"
        @tracker.register_message(@event["from"], @event["server_gmt"], @people["gender"])
      end
      @messages[key] = "#{@event['server_gmt']}#{@event['from']}"
      @last_call = Time.now.to_i
      # end
    end

    def html_link(profile)
      "<a href='http://www.okcupid.com/profile/#{profile}'>profile</a>"
    end

    def looks_vote
      @log.debug "looks_vote: #{@event["from"]}"
    end

    def im
      # unless @events_hash.has_key(this_event_time)
      puts "New IM from #{@event["from"]}" #unless @event["server_gmt"] == @gmt
      # @tracker.register_message(@event["screenname"], @event["server_gmt"])
      # end
      # @events_hash[this_event_time] = @event["screenname"]
      @event
    end

    def orbit_picture_upload
      #something
    end

    def stalk
      people = @people
      event = @event
      unless @stalks.has_key?(event["server_gmt"])
        @tracker.register_visit(people)
      end
      @stalks[event["server_gmt"]] = people["screenname"]
    end


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

    def toolbar_trigger
      @log.debug "Toolbar trigger"
      # print_event_info
    end


    # needs @event
    def orbit_user_signoff
      @log.debug "orbit_user_signoff: #{@event['screenname']}"
    end

    # needs @event
    def orbit_user_signon
      @log.debug "orbit_user_signon: #{@event['screenname']}"
    end

    # needs @event
    def orbit_nth_question
      @log.debug "orbit_nth_question: #{@event['screenname']}"
    end



  end
end
