require './includes'

class EventWatcher

  def initialize(args)
    # puts "Initializing browser..."
    # @browser = Session.new(:username => @username, :password => password)
    @browser = args[ :browser]
    @tracker = args[ :tracker]
    @log     = args[ :logger]

    @m_last_event_time = 0
    @s_last_event_time = 0
    @i_last_event_time = 0
    @events_hash = Hash.new { |hash, key| hash[key] = 0 }
    @instant_instance = 1
  end

  def long_poll_result
    request_id = Time.now.to_i
    response = @browser.body_of(api_url, request_id)
    until response[:hash].to_i == request_id
      response = @browser.body_of(api_url, request_id)
    end
    response[:body]
  end

  def login
    @browser.login
  end

  def html
    @body.current_user
  end

  def logout
    @browser.logout
  end

  def api_url
    # @instant_instance = 1 if @instant_instance > 2
    result = "http://1-instant.okcupid.com/instantevents?random=#{rand}"
    # @instant_instance += 1
    result
  end

  def this_event_time
    @event["server_gmt"].to_i
  end

  def content
    (/(\{.+\})/.match(long_poll_result)[1])
  end

  def poll_response
    begin
      JSON.parse(content.gsub('\"', '"')).to_hash
    rescue JSON::ParserError
      content.to_hash
    end
  end

  def msg_notify
    # unless @events_hash.has_key(this_event_time)
    puts "New message from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
    @tracker.register_message(@event["screenname"], this_event_time)
    # end
    # @events_hash[this_event_time] = @event["screenname"]
    @event
  end

  def im
    # unless @events_hash.has_key(this_event_time)
    puts "New IM from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
    # @tracker.register_message(@event["screenname"], @event["server_gmt"])
    # end
    # @events_hash[this_event_time] = @event["screenname"]
    @event
  end

  def stalk
    # unless @events_hash.has_key(this_event_time)
    puts "New visit from #{@event['screenname']}"
    @tracker.register_visit(@event)
    # end
    # @events_hash[this_event_time] = @event["screenname"]
    @event
  end

  def orbit_user_signoff
    @log.debug "orbit_user_signoff: #{@event['screenname']}"
  end

  def check_events
    response = poll_response
    count = 0
    unless response == nil
      # begin
      response["events"].each do |event|
        if event.respond_to?(:has_key)
          if event.has_key?('from')
            @index = count
          end
          count += 1
        end
      end
      # rescue
      # p response
      # end
      if @index && response["events"][@index]
        @event = response["events"][@index]
        @details = response["people"]
        @event = @event.merge(@details[@details.size - 1]) unless @details[@details.size - 1] == nil
        response = @event["type"]
        unless @events_hash.has_key(this_event_time)
          begin
            self.send(response)
          rescue
            @log.debug "#{response}: #{@event['screenname']}"
          end
          @events_hash[this_event_time] = @event["screenname"]
        end
      end
    end
    # unread = response["num_unread"].to_i
    nil
  end

  def new_mail
    poll_response['num_unread'].to_i
  end
end
