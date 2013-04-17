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
    @browser.go_to("http://www.okcupid.com/visitors")
    @current_user       = @browser.current_user
    @visitors_page      = @current_user.parser.xpath("//div[@id='main_column']").to_html
    @details    = @visitors_page.scan(/>([\w\d]+).+(\d{2}) \/ (F|M)\s\/\s(\w+)\s\/\s[\w\s]+.+"location".([\w\s]+)..([\w\s]+)/)

    puts @visitors_page if debug
    wait = gets.chomp if debug

    @gender     = Hash.new("Q")
    @age        = Hash.new(0)
    @sexuality  = Hash.new(0)
    @state      = Hash.new(0)
    @city       = Hash.new(0)

    @details.each do |user|
      handle              = user[0]
      age                 = user[1]
      gender              = user[2]
      sexuality           = user[3]
      city                = user[4]
      state               = user[5]
      @gender[handle]     = gender
      @state[handle]      = state
      @city[handle]       = city
      @state[handle]      = state
      @sexuality[handle]  = sexuality
      @age[handle]        = age

      puts user if debug && gender == "Q"
    end

    visitor_list   = @visitors_page.scan(/"usr-([\w\d]+)".+z\-index\:\s(\d\d\d)/)
    @count  = 0
    visitor_list.each do |visitor, zindex|

      @timestamp_block  = @current_user.parser.xpath("//div[@id='usr-#{visitor}-info']/p/script/text()").to_html
      @timestamp        = @timestamp_block.match(/(\d{10}), 'JOU/)[1].to_i
      @stored_timestamp = @db.get_visitor_timestamp(visitor).to_i

      unless @stored_timestamp == @timestamp
        @count += 1

        puts visitor if verbose

        puts "Scraped gender: #{@gender[visitor]}" if verbose
        puts "Setting gender: #{@settings.gender}" if verbose


        @db.add_user(visitor) unless @gender[visitor] == "Q"

        @db.ignore_user(visitor) unless @gender[visitor] == @settings.gender

        @db.set_gender(:username => visitor, :gender => @gender[visitor])
        @db.set_state(:username => visitor, :state => @state[visitor])

        increment_visitor_counter(visitor)
      end

      @db.set_visitor_timestamp(visitor, @timestamp.to_i)
    end

    @db.stats_add_visitors(@count.to_i)
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
