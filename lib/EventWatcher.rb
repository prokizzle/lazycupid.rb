require './includes'

class EventWatcher

  def initialize(args)
    # puts "Initializing browser..."
    # @browser = Session.new(:username => @username, :password => password)
    @browser = args[ :browser]
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

  def poll_response
    JSON.parse(/(\{.+\})/.match(long_poll_result)[1]).to_hash
  end

  def check_events
    @last_user = ""
    events = Array.new
    # until events.size > 3
    @location = Array.new
    @match = Array.new
    @age = Array.new
    @sexuality = Array.new
    @distance = Array.new
    @gender = Array.new
    people = Array.new
    @result = Array.new
    # puts "Waiting for response..."
    response = poll_response
    # puts "Response received.",""
    # puts response, ""
    # puts response.to_yaml
    unread = response["num_unread"].to_i
    events = response["events"]
    people = response["people"]
    user = Array.new
    @event_index = 0
    @people_index = 0
    # if people.size > 0
    people.each do |person|
      @location[@people_index]  = person["location"]
      @match[@people_index]     = person["match"]
      @age[@people_index]       = person["age"]
      @sexuality[@people_index] = person["orientation"]
      @distance[@people_index]  = person["distance"]
      @gender[@people_index]    = person["gender"]
      @people_index += 1
    end
    # end
    events.each do |event|
      @result.push({
                     handle: event['from'],
                     type: event['type'],
                     time: event['server_gmt'],
                     location: @location[@event_index],
                     match: @match[@event_index],
                     age: @age[@event_index],
                     sexuality: @sexuality[@event_index],
                     distance: @distance[@event_index],
                     gender: @gender[@event_index]
      })
      @event_index += 1
      # puts @last_user
    end
    @result
    # sleep 20
    # end
  end

  def new_mail
    poll_response['num_unread'].to_i
  end
end