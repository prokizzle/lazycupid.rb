
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
    @spotlight  = Hash.new
    @messages   = Hash.new
    @stalks     = Hash.new
    @looks_vote = Hash.new
    @new_events = Array.new
    @new_people = Array.new
    @hash = Hash.new { |hash, key| hash[key] = 0 }
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
    unless @messages.has_key?(@event["server_gmt"])
      puts "New message from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
      @tracker.register_message(@event["screenname"], this_event_time)
    end
    @messages[@event["server_gmt"]] = @people["screenname"]
  end

  def looks_vote

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
    unless @stalks.has_key?(@event["server_gmt"])
      puts "New visit from #{@event['screenname']}"
      @tracker.register_visit(@event)
    end
    @stalks[@event["server_gmt"]] = @people["screenname"]
  end

  def new_spotlight_user
    unless @spotlight.has_key?(@event["server_gmt"])
      puts "New spotlight user: #{@people["screenname"]}"
      @spotlight[@event["server_gmt"]] = @people["screenname"]
    end
    print_event_info
  end

  def toolbar_trigger
    puts "Toolbar trigger"
    print_event_info
  end

  def orbit_user_signoff
    @log.debug "orbit_user_signoff: #{@event['screenname']}"
  end

  def process(event, people)
    @event = event
    @people = people
    type = event["type"]
    self.send(type)
  end

  def check_events
    # if app.check_events.respond_to?('each')

    # puts "Requesting..."
    temp = poll_response
    # puts "Reponse received."
    count = 0
    # puts temp["events"]
    # puts temp["im_off"]
    # puts temp["num_unread"]
    # puts temp["people"]
    # puts temp["server_seqid"]
    # puts temp
    events_array = temp["events"]
    people_array = temp["people"]
    events_array_size = events_array.size
    index = 0
    people_array.size.to_i.times do
      current_event_hash = events_array.shift
      current_people_hash = people_array.shift
      unless current_event_hash == nil && current_people_hash == nil
        current_event_hash.merge(current_people_hash)
        gmt = current_event_hash["server_gmt"]
        @new_events.push(current_event_hash)
        @new_people.push(current_people_hash)
        unless @hash.has_key?(gmt.to_i)
          x_temp = @new_events.shift
          y_temp = @new_people.shift
          # puts "Processing: #{x_temp}","for #{current_people_hash["screenname"]} who is #{current_event_hash["from"]}"
          process(x_temp, y_temp)
        end
        @hash[gmt.to_i] = current_event_hash
        # puts hash
        # sleep 4
      end
    end
  end

  def new_mail
    poll_response['num_unread'].to_i
  end
end
