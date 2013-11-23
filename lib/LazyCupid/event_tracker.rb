module LazyCupid
  class EventTracker
    require_relative 'global_regex'
    attr_reader :body

    def initialize(args)
      @browser = args[:browser]
      @db = args[:database]
      @settings = args[ :settings]
      @prev_total_messages = -1
    end

    def current_user
      @html
    end

    def body_of(url)
      request_id = Time.now.to_i
      result = @browser.body_of("http://www.okcupid.com/visitors", request_id)
      @browser.delete_response(request_id)
      @html = result[:html]
      @body = result[:body]
      result
    end

    def add_user(user, gender)
      @db.add_user(user.to_s, gender, caller[0][/`.*'/].to_s.match(/`(.+)'/)[1])
    end

    def parse_visitors_page
      @db.remove_unknown_gender
      @visitors = Array.new
      @final_visitors = Array.new
      request_id = Time.now.to_i
      result = @browser.body_of("http://www.okcupid.com/visitors", request_id)
      @html = result[:html]
      @body = result[:body]
      @browser.delete_response(request_id)

      page = @html.parser.xpath("//div[@id='main_column']/div").to_html
      users = page.scan(/.p.class=.user_name.>(.+)<\/p>/)
      users.each do |user|
        block = user.shift
        handle = block.match(/\/profile\/(.+)\?cf=visitors"/)[1]
        aso = block.match(/aso.>(.+)<.p/)[1]
        age = aso.match(/(\d{2})/)[1].to_i
        gender = aso.match(/#{age} \/ (\w) \//)[1]
        sexuality = aso.match(/#{age} \/ #{gender} \/ (\w+) \//)[1]
        status = aso.match(/#{age} \/ #{gender} \/ #{sexuality} \/ ([\w\s]+)/)[1]
        location = block.match(/location.+>(.+)/)[1]
        city = RegEx.parsed_location(location)[:city]
        state = RegEx.parsed_location(location)[:state]
        @visitors.push({handle: handle, age: age, gender: gender, sexuality: sexuality, status: status, city: city, state: state})
      end


      until @visitors.empty?
        user = @visitors.shift
        block = @html.parser.xpath("//div[@id='usr-#{user[:handle]}-info']/p[1]/script/text()
    ").text
        timestamp = block.match(/(\d+), .JOURNAL/)[1]
        addition = {timestamp: timestamp}
        final = user.merge(addition)
        @final_visitors.push(final)
        # puts block
      end
      @count = 0
      until @final_visitors.empty?

        user = @final_visitors.shift
        @stored_timestamp = @db.get_visitor_timestamp(user[:handle]).to_i

        unless @stored_timestamp == user[:timestamp]
          @count += 1
          @db.add_user(user[:handle], user[:gender], "visitors")
          @db.ignore_user(user[:handle]) unless user[:gender] == @settings.gender
          @db.set_gender(:username => user[:handle], :gender => user[:gender])
          @db.set_state(:username => user[:handle], :state => user[:state])

          @db.increment_visitor_counter(user[:handle])
          @db.set_visitor_timestamp(user[:handle], user[:timestamp])
        end
      end
      @db.stats_add_visitors(@count.to_i)
      @count.to_i
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
      city      = RegEx.parsed_location(location)[:city]
      state     = RegEx.parsed_location(location)[:state]
      @stored_timestamp = @db.get_visitor_timestamp(visitor).to_i

      unless @stored_timestamp == timestamp
        puts "* New visitor: #{visitor} *"


        @db.add_user(visitor, gender, "api_visitor")
        @db.ignore_user(visitor) unless gender == $gender || gender == $alt_gender
        # @db.set_gender(:username => visitor, :gender => gender)

        @db.set_city(visitor, city)
        @db.set_state(:username => visitor, :state => state)
        @db.set_estimated_distance(visitor, city, state)

        @db.increment_visitor_counter(visitor)
      end
      @db.set_visitor_timestamp(visitor, timestamp)
      @db.stats_add_visitor
    end

    def visitor_event
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
          :city        => RegEx.parsed_location(location)[:city],
          :state       => RegEx.parsed_location(location)[:state]
        }

        track_visitor(person)
      end
    end

    def track_msg_dates(msg_page)
      result = async_response(msg_page)
      message_list = result[:body].scan(/"message_(\d+)"/)
      @total_msg_on_page = message_list.size
      message_list.each do |message_id|
        begin
          message_id      = message_id.first
          msg_block       = result[:html].parser.xpath("//li[@id='message_#{message_id}']").to_html
          # unless !(msg_block =~ /"subject">OKCupid!</).nil?
          sender          = /\/([\w\d_-]+)\?cf=messages/.match(msg_block)[1]
          timestamp_block = result[:html].parser.xpath("//li[@id='message_#{message_id.to_s}']/span/script/text()").to_html
          timestamp       = timestamp_block.match(/(\d{10}), 'MAI/)[1].to_i
          sender          = sender.to_s
          gender          = "Q"
          # r = {"sender" => sender, "timestamp" => timestamp, "gender" => gender}
          # puts r
          register_message(sender, timestamp, gender)
          # end
        rescue
          puts "Error tracking message"
        end
      end
    end

    def register_message(sender, timestamp, gender)
      # @stored_time     = @db.get_last_received_message_date(sender).to_i
      if timestamp.to_i >= Time.now.to_i - 1800
        puts "New message from #{sender}"
      end

      @db.add_user(sender, gender, "inbox")
      @db.ignore_user(sender)

      # unless @stored_time == timestamp.to_i
      # puts "New message found: #{sender} at #{Time.at(timestamp)}"
      # p "Old timestamp: #{@stored_time}"
      # p "New timestamp: #{timestamp}"
      # @db.increment_received_messages_count(sender)
      # @db.set_last_received_message_date(sender, timestamp.to_i)
      # unless @db.get_user_info(sender)[0]["last_msg_time"] == timestamp
      # @db.delete_user(sender)
      # end
      # @db.stats_add_new_message
      # end
    end

    def default_match_search
      5.times { test_more_matches(MatchQueries.default_query) } if $scrape_match_search
    end

    def test_more_matches(query="http://www.okcupid.com/match?timekey=1384469612&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&match_card_class=just_appended&low=81&count=10&ajax_load=1")
      # begin
      # result = @browser.body_of("http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1", Time.now.to_i)
      result = async_response(query)
      parsed = JSON.parse(result[:html].content).to_hash
      html = parsed["html"]
      @details = html.scan(/<div id="usr-([\w\d_-]+)-wrapper" class="match_card_wrapper user-not-hidden ">/)
      html_doc = Nokogiri::HTML(html)

      @gender, @age, @state, @city     = {}
        @details.each do |user|
          result2 = html_doc.xpath("//div[@id='usr-#{user[0]}-wrapper']").to_s
          age = result2.match(/span.class=.age.>(\d{2})/)[1].to_i
          gender = $gender
          username = user[0].to_s
          puts "username: #{username}, age: #{age}, gender: #{gender}"  if $debug
          city, state   = String.new
          location      = /span.class=.dot.>·<.span>(.+)$/.match(result2)[1]
          city          = RegEx.parsed_location(location)[:city]
          state         = RegEx.parsed_location(location)[:state]
          puts "city: #{city}, state: #{state}" if $debug
          match_percent = /(\d+)% Match/.match(result2)[1]
          puts "#{username} #{match_percent} match" if $debug
          @db.add(username: username, gender: gender, added_From: "ajax_match_search", age: age, city: city, state: state, match_percent: match_percent, age: age)
        end

      # @db.close
      # rescue Exception => e
      # puts e.message
      # Exceptional.handle(e, 'More matches scraper')
      # end
    end

    def async_response(url)
      result = Hash.new
      request_id = Time.now.to_i
      @browser.send_request(url, request_id)
      until result[:ready] == true
        result = @browser.get_request(request_id)
      end
      # p result
      @browser.delete_response(request_id)
      result
    end

    def parse_inbox_page(url)
      result = async_response(url)
      message_list = result[:body].scan(/id\="message_(\d+)"/)
      message_list.each do |id|
        thread = result[:html].parser.xpath("//li[@id='message_#{id[0]}']")
        info = thread.to_html.match(/([-\w\d_]+)\?cf=messages..class="photo">.+src="(.+)" border.+threadid.(\d+).+fancydate_\d+.. (\d+),/)
        @messages.push({handle: info[1], photo_thumbnail: info[2], thread_id: info[3], thread_url: "http://www.okcupid.com/messages?readmsg=true&threadid=#{info[3]}&folder=1", message_date: info[4]})
      end
    end

    def analyze_message_thread(thread)
      request = @browser.request(thread[:thread_url], Time.now.to_i)
      # thread_html = request[:html]
      thread_page = request[:body]
      replies = thread_page.scan(/Report this/)
      thread[:replies] = replies.size
      # puts "#{thread[:handle]} #{replies.size} replies"
      # puts "#{thread[:handle]} #{thread[:message_date]}"
      puts thread
    end

    def scrape_inbox
      puts "Scraping inbox" if $verbose
      result = async_response("http://www.okcupid.com/messages")
      # begin
      begin
        # @total_msg = result[:body].match(/Page 1 of <a href="\/messages\?low\=(\d+)\&amp\;folder\=1">\d+/)[1].to_i
        @total_msg = result[:body].match($total_messages)[1].to_i
      rescue
        @total_msg = 0
      end
      # @total_msg    = total_pages * 30
      # rescue
      # @total_msg    = 0
      # end
      puts "Total messages: #{@total_msg}" if $verbose
      sleep 2
      unless @total_msg == @prev_total_messages
        track_msg_dates("http://www.okcupid.com/messages")
        if @total_msg > 0
          puts "#{@total_msg - @prev_total_messages} new messages..."
        else
          puts @total_msg_on_page
          @total_msg = @total_msg_on_page
        end
        low = 31
        until low >= @total_msg
          # puts "Scraping inbox: #{((low.to_f/@total_msg.to_f)*100).to_i}%" if $debug
          # puts low if $debug
          low += 30
          track_msg_dates("http://www.okcupid.com/messages?low=#{low}&folder=1")
          sleep (1..6).to_a.sample.to_i
        end
        @prev_total_messages = @total_msg
      end
    end

    def scrape_im_page
      puts "Scraping IM page" if $verbose
      result = async_response("http://www.okcupid.com/imhistory")
    end
  end
end
