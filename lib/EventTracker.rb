class EventTracker

  def initialize(args)
    @browser = args[ :browser]
    @db = args[:database]
    @settings = args[ :settings]
  end

  def body
    @browser.body
  end

  def current_user
    @browser.current_user
  end

  def verbose
    @verbose
  end

  def debug
    @debug
  end



  def increment_visitor_counter(visitor)
    original      = @db.get_visitor_count(visitor)
    new_counter   = original + 1

    @db.set_visitor_counter(visitor, new_counter)
  end

  def increment_message_counter(user)
    original = @db.get_received_messages_count(user)
    new_counter = original + 1
    @db.stats_add_new_messages(1)

    @db.set_received_messages_count(user, new_counter)
  end

  def parse_visitors_page
    @database.remove_unknown_gender
    @visitors = Array.new
    @final_visitors = Array.new

    @browser.go_to("http://www.okcupid.com/visitors")

    page = current_user.parser.xpath("//div[@id='main_column']/div").to_html
    users = page.scan(/.p.class=.user_name.>(.+)<\/p>/)
    users.each do |user|
      block = user.shift
      handle = block.match(/visitors.>(.+)<.a/)[1]
      aso = block.match(/aso.>(.+)<.p/)[1]
      age = aso.match(/(\d{2})/)[1].to_i
      gender = aso.match(/#{age} \/ (\w) \//)[1]
      sexuality = aso.match(/#{age} \/ #{gender} \/ (\w+) \//)[1]
      status = aso.match(/#{age} \/ #{gender} \/ #{sexuality} \/ ([\w\s]+)/)[1]
      location = block.match(/location.+>(.+)/)[1]
      city = location_array(location)[:city]
      state = location_array(location)[:state]
      @visitors.push({handle: handle, age: age, gender: gender, sexuality: sexuality, status: status, city: city, state: state})
    end


    until @visitors.size == 0
      user = @visitors.shift
      block = current_user.parser.xpath("//div[@id='usr-#{user[:handle]}-info']/p[1]/script/text()
    ").text
      timestamp = block.match(/(\d+), .JOURNAL/)[1]
      addition = {timestamp: timestamp}
      final = user.merge(addition)
      @final_visitors.push(final)
      # puts block
    end
    @count = 0
    until @final_visitors.size == 0

      user = @final_visitors.shift
      @stored_timestamp = @database.get_visitor_timestamp(user[:handle]).to_i

      unless @stored_timestamp == user[:timestamp]
        @count += 1
        @database.add_user(user[:handle])
        @database.ignore_user(user[:handle]) unless user[:gender] == @settings.gender
        @database.set_gender(:username => user[:handle], :gender => user[:gender])
        @database.set_state(:username => user[:handle], :state => user[:state])

        increment_visitor_counter(user[:handle])
        @database.set_visitor_timestamp(user[:handle], user[:timestamp])
      end
    end
    @database.stats_add_visitors(@count.to_i)
    @count.to_i
  end

  def parsed_location(location)
    result    = location.scan(/,/)
    if result.size == 2
      city    = location.match(/(.+), (.+), (.+)/)[1]
      state   = location.match(/(.+), (.+), (.+)/)[2]
      country = location.match(/(.+), (.+), (.+)/)[3]
    elsif result.size == 1
      city    = location.match(/(.+), (.+)/)[1]
      state   = location.match(/(.+), (.+)/)[2]
    end
    {:city => city, :state => state}
  end

  def translate_sexuality(orientation)
    case orientation
    when "S"
      "Straight"
    when "B"
      "Bisexual"
    when "G"
      "Gay"
    end
  end

  def register_visit(person)
    visitor   = person['screenname']
    timestamp = person['server_gmt']
    gender    = person['gender']
    distance  = person['distance']
    match     = person['match']
    age       = person['age']
    sexuality = translate_sexuality(person['orientation'])
    location  = person['location']
    city      = parsed_location(location)[:city]
    state     = parsed_location(location)[:state]
    @stored_timestamp = @db.get_visitor_timestamp(visitor).to_i

    unless @stored_timestamp == timestamp
      puts "*****************","New visitor: #{visitor}","*****************"


      @db.add_user(visitor)
      @db.ignore_user(visitor) unless gender == @settings.gender
      @db.set_gender(:username => visitor, :gender => gender)
      @db.set_state(:username => visitor, :state => state)

      increment_visitor_counter(visitor)
    end
    @db.set_visitor_timestamp(visitor, timestamp)
    @db.stats_add_visitors(1)
  end

  def prepare_visit
    response = @events.check_events
    unless response == nil
      person = {
        :visitor     => response[:handle],
        :timestamp   => response[:time].to_i,
        :gender      => response[:gender],
        :distance    => response[:distance],
        :match       => response[:match],
        :sexuality   => response[:sexuality],
        :location    => response[:location],
        :city        => location_array(location)[:city],
        :state       => location_array(location)[:state]
      }

      track_visitor(person)
    end
  end

  def do_page_action(url)
    puts "","Scraping: #{url}" if verbose
    @browser.go_to(url)
    track_msg_dates
    sleep 2
  end

  def track_msg_dates
    message_list = body.scan(/"message_(\d+)"/)

    message_list.each do |message_id|

      message_id      = message_id[0]
      msg_block       = current_user.parser.xpath("//li[@id='message_#{message_id}']").to_html
      sender          = /\/([\w\d_-]+)\?cf=messages/.match(msg_block)[1]
      timestamp_block = current_user.parser.xpath("//li[@id='message_#{message_id.to_s}']/span/script/text()").to_html
      timestamp       = timestamp_block.match(/(\d{10}), 'MAI/)[1].to_i
      sender          = sender.to_s

      register_message(sender, timestamp)

    end
  end

  def register_message(sender, timestamp)
    @stored_time     = @db.get_last_received_message_date(sender)

    @db.ignore_user(sender)

    unless @stored_time == timestamp
      increment_message_counter(sender)
      @db.set_last_received_message_date(sender, timestamp)
    end
  end
end
