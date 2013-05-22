class APIEvents

  # if you come across an unknown API event, add it to attr_reader as a workaround
  attr_reader :orbit_vote, :verbose, :debug

  def initialize(args)
    @tracker = args[ :tracker]
    @log     = args[ :logger]
    @spotlight  = Hash.new
    @messages   = Hash.new
    @stalks     = Hash.new
  end

  def process(event, people)
    @event = event
    @people = people
    type = event["type"]
    self.send(type)
  end

  def msg_notify
      puts "New message from #{@event["screenname"]}" #unless @event["server_gmt"] == @gmt
    unless @messages.has_key?(@event["server_gmt"])
      @tracker.register_message(@event["screenname"], this_event_time)
    end
    @messages[@event["server_gmt"]] = @people["screenname"]
  end

  def looks_vote
    @log.debug "looks_vote: #{@event["screenname"]}"
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
      # puts "New visit from #{@event['screenname']}"
      @tracker.register_visit(@people)
    end
    @stalks[@event["server_gmt"]] = @people["screenname"]
  end

  def new_spotlight_user
    handle_ = @people["screenname"]
    gmt_ = @event["server_gmt"]
    unless @spotlight.has_key?(gmt_)
      puts "New spotlight user: #{handle_} (#{@people["gender"]})" #if verbose
      @tracker.add_user(handle_, @people["gender"])
      @spotlight[gmt_] = handle_
    end
    # print_event_info
  end

  def toolbar_trigger
    @log.debug "Toolbar trigger"
    # print_event_info
  end

  def orbit_user_signoff
    @log.debug "orbit_user_signoff: #{@event['screenname']}"
  end

  def orbit_user_signon
    @log.debug "orbit_user_signon: #{@event['screenname']}"
  end

  def orbit_nth_question
    @log.debug "orbit_nth_question: #{@event['screenname']}"
  end



end
