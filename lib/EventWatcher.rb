require './includes'

class EventWatcher

  def initialize(args)
    # puts "Initializing browser..."
    # @browser = Session.new(:username => @username, :password => password)
    @browser = args[ :browser]
    @tracker = args[ :tracker]

    @last_event_time = 0

  end

  def long_poll_result
    @browser.go_to(api_url)
  end

  def login
    @browser.login
  end

  def logout
    @browser.logout
  end

  def api_url
    "http://api.okcupid.com/instantevents?random=#{rand}"
  end

  def content
  (/(\{.+\})/.match(long_poll_result)[1])
end

  def poll_response
    JSON.parse(content.gsub('\"', '"')).to_hash
  end

  def msg_notify
    unless @event["server_gmt"].to_i == @last_event_time
      puts "New message from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
      @tracker.register_message(@event["screenname"], @event["server_gmt"])
    end
    @last_event_time = @event["server_gmt"].to_i
    @event
  end

  def im
    unless @event["server_gmt"].to_i == @last_event_time
      puts "New IM from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
      # @tracker.register_message(@event["screenname"], @event["server_gmt"])
    end
    @last_event_time = @event["server_gmt"].to_i
    @event
  end

  def stalk
    unless @event["server_gmt"].to_i == @last_event_time
      puts "New visit from #{@event['screenname']}"
      @tracker.register_visit(@event)
    end
    @last_event_time = @event["server_gmt"].to_i
    @event
  end

  def check_events
    response = poll_response
    count = 0
    unless response == nil
      response["events"].each do |event|
        if event.has_key?('from')
          @index = count
        end
        count += 1
      end
      if @index && response["events"][@index]
        @event = response["events"][@index]
        @details = response["people"]
        @event = @event.merge(@details[@details.size - 1])
        response = @event["type"]
        self.send(response)
      end
    end
    unread = response["num_unread"].to_i
    nil
  end

  def new_mail
    poll_response['num_unread'].to_i
  end
end
