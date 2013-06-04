
require './includes'
class EventWatcher
  attr_reader :debug, :verbose

  def initialize(args)
    # puts "Initializing browser..."
    # @browser = Browser.new(:username => @username, :password => password)
    @browser    = args[:browser]
    @tracker    = args[:tracker]
    @log        = args[:logger]
    @settings   = args[:settings]

    @api        = APIEvents.new(tracker: @tracker, logger: @log, settings: @settings)

    @spotlight  = Hash.new
    @messages   = Hash.new
    @stalks     = Hash.new
    @looks_vote = Hash.new
    @new_events = Array.new
    @new_people = Array.new
    @people_hash = Hash.new
    @hash = Hash.new { |hash, key| hash[key] = 0 }
    @events_hash = Hash.new { |hash, key| hash[key] = 0 }
    @instant = 2
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

  def logout
    @browser.logout
  end

  def api_url
    case @instant
    when @instant < 4
      @instant += 1
    else
      @instant = 1
    end
    i = @instant
    "http://#{i}-instant.okcupid.com/instantevents?random=#{rand}&server_gmt=#{Time.now.to_i}"
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
      # content.to_hash
    end
  end

  def check_events

    temp              = poll_response
    index             = 0

    temp["people"].each do |user|
      unless @people_hash.has_key?(user["screenname"])
        @people_hash[user["screenname"]] = user
      end
    end

    begin
      temp["events"].each do |event|
        key = "#{event['server_gmt']}#{event['type']}"
        unless @hash[key] == event["server_seqid"]
          @api.process(event, @people_hash[event['from']], key)
          @hash[key] = event["server_seqid"]
        end

      end
    rescue
      # puts "*****"
      @log.debug temp["events"]
      # puts "*****"
    end

  end

  def new_mail
    poll_response['num_unread'].to_i
  end
end
