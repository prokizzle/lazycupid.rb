module LazyCupid
  class EventTracker
    # include RegEx
    # include MatchQueries

    attr_reader :verbose, :debug, :body, :account

    def initialize(args)
      @browser = args[ :browser]
      @db = args[:database]
      @settings = args[ :settings]
      # @regex = RegEx.new
      @account = @db.login
      @prev_total_messages = 0
      @queries = MatchQueries.new
      @regex = RegEx.new
    end

    def current_user
      @html
    end

    def body_of(url)
      result = @browser.body_of("http://www.okcupid.com/visitors", Time.now.to_i)
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

      result = @browser.body_of("http://www.okcupid.com/visitors", Time.now.to_i)
      @html = result[:html]
      @body = result[:body]

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
        city = @regex.parsed_location(location)[:city]
        state = @regex.parsed_location(location)[:state]
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
      city      = @regex.parsed_location(location)[:city]
      state     = @regex.parsed_location(location)[:state]
      @stored_timestamp = @db.get_visitor_timestamp(visitor).to_i

      unless @stored_timestamp == timestamp
        puts "* New visitor: #{visitor} *"


        @db.add_user(visitor, gender, "api_visitor")
        @db.ignore_user(visitor) unless gender == @settings.gender
        # @db.set_gender(:username => visitor, :gender => gender)
        @db.set_state(:username => visitor, :state => state)

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
          :city        => @regex.parsed_location(location)[:city],
          :state       => @regex.parsed_location(location)[:state]
        }

        track_visitor(person)
      end
    end

    def track_msg_dates(msg_page)
      result = async_response(msg_page)
      message_list = result[:body].scan(/"message_(\d+)"/)

      message_list.each do |message_id|
        message_id      = message_id[0]
        msg_block       = result[:html].parser.xpath("//li[@id='message_#{message_id}']").to_html
        sender          = /\/([\w\d_-]+)\?cf=messages/.match(msg_block)[1]
        timestamp_block = result[:html].parser.xpath("//li[@id='message_#{message_id.to_s}']/span/script/text()").to_html
        timestamp       = timestamp_block.match(/(\d{10}), 'MAI/)[1].to_i
        sender          = sender.to_s
        gender          = "Q"

        register_message(sender, timestamp, gender)

      end
    end

    def register_message(sender, timestamp, gender)
      # @stored_time     = @db.get_last_received_message_date(sender).to_i

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
      test_more_matches(@queries.default_query)
    end

    def focus_new_users
      @queries.focus_new_users_query
    end




    def test_more_matches(query="http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1")
      begin
        # result = @browser.body_of("http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=11&count=10&&filter7=6,604800&ajax_load=1", Time.now.to_i)
        result = async_response(query)
        parsed = JSON.parse(result[:html].content).to_hash
        html = parsed["html"]
        @details = html.scan(/<div class="match_row match_row_alt\d clearfix " id="usr-([\w\d_-]+)">/)
        html_doc = Nokogiri::HTML(html)
        # @db.open

        @gender     = Hash.new("Q")
        @age        = Hash.new(0)
        # @sexuality  = Hash.new(0)
        @state      = Hash.new(0)
        @city       = Hash.new(0)

        @details.each do |user|
          result = html_doc.xpath("//div[@id='usr-#{user[0]}']/div[1]/div[1]/p[1]").to_s

          age = "#{result.match(/(\d{2})/)}".to_i
          gender = "#{result.match(/(M|F)</)[1]}"
          result = html_doc.xpath("//div[@id='usr-#{user[0]}']/div[1]/div[1]/p[2]").to_s
          # puts city, state
          username = user[0].to_s
          @db.add_user(username, gender, "ajax_match_search")
          # @db.set_gender(:username => username, :gender => gender)
          @db.set_age(username, age)
          begin
            city = ""
            state = ""
            location = /location.>(.+)</.match(result)[1]
            city = @regex.parsed_location(location)[:city]
            state = @regex.parsed_location(location)[:state]
            @db.set_city(username, city)
            @db.set_state(:username => username, :state => state)
          rescue Exception => e
            puts e.message
            # Exceptional.handle(e, 'Location reg ex')
          end
        end

        # @db.close
      rescue Exception => e
        puts e.message
        # Exceptional.handle(e, 'More matches scraper')
      end
    end

    def async_response(url)
      result = Hash.new
      result[:hash] = 0
      timekey = Time.now.to_i
      until result[:hash] == timekey
        result = @browser.body_of(url, timekey)
      end
      # p result
      result
    end

    def scrape_inbox
      puts "Scraping inbox" if verbose
      result = async_response("http://www.okcupid.com/messages")
      @total_msg    = result[:body].match(/"pg_total.>(\d+)</)[1].to_i
      puts "Total messages: #{@total_msg}" if verbose
      sleep 2
      unless @total_msg == @prev_total_messages
        puts "#{@total_msg - @prev_total_messages} new messages..." if @total_msg > 0
        track_msg_dates("http://www.okcupid.com/messages")
        low = 31
        until low >= @total_msg
          low += 30
          track_msg_dates("http://www.okcupid.com/messages?low=#{low}&folder=1")
          sleep (1..6).to_a.sample.to_i
        end
        @prev_total_messages = @total_msg
      end
    end

  end
end