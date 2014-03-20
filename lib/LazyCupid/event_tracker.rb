module LazyCupid
  class EventTracker
    require_relative 'global_regex'
    attr_reader :body

    def initialize(args)
      @browser = args[:browser]
      @db = args[:database]
      @settings = args[ :settings]
      @prev_total_messages = -1
      @visit_events = Array.new
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

    # [todo] - add incoming_visits table, or update model if already exists
    # [todo] - create a new visitor row here instead of updating stats or matches tables
    def register_visit(person)
      unless @visit_events.include? person['server_gmt']
        visitor   = person['screenname']
        server_gmt   = person['server_gmt'].to_i
        server_seqid = person['server_seqid'].to_s
        gender    = person['gender']
        distance  = person['distance']
        match     = person['match']
        age       = person['age']
        sexuality = translate_sexuality(person['orientation'])
        location  = person['location']
        city      = RegEx.parsed_location(location)[:city]
        state     = RegEx.parsed_location(location)[:state]

        # Determines if current visitor event is the same as the last one stored in db, aka, not a duplicate event
        # @stored_timestamp = @db.get_visitor_timestamp(visitor).to_i

        # If it's not a duplicate
        # puts "*******","Visit unique!","*******"
        unless IncomingVisit.where(server_seqid: server_seqid.to_s).exists
          puts "* New visitor: #{visitor} *"

          # Add the user to the matches table
          # @db.add_user(username: visitor, gender: gender, added_from: "api_visitor", city: city, state: state, )


          IncomingVisit.find_or_create(name: person['screenname'], server_gmt: Time.at(person['server_gmt']), server_seqid: person['server_seqid'].to_s, account: $login)

          # Increment their visit count for current account
          @db.stats_add_visitor
          # end

          # Set time for visit
          @db.set_visitor_timestamp(visitor, server_gmt)

          # Increment total visits in stats table
          @visit_events << person['server_seqid']
        end
      end
    end



    def default_match_search(number=3)
      number.times { scrape_match_search_page(MatchQueries.default_query) } if $scrape_match_search
    end

    def scrape_match_search_page(query="http://www.okcupid.com/match?timekey=#{Time.now.to_i}&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&count=18&ajax_load=1")
      result        = async_response(query)
      # puts result[:body]
      parsed        = JSON.parse(result[:html].content).to_hash
      # puts parsed
      html          = parsed["html"]
      # puts html
      # sleep 100
      @details      = html.scan(/<div id="usr-([\w\d_-]+)-wrapper" class="match_card_wrapper user-not-hidden ">/)
      b_test        = true if @details.empty?
      @details      ||= html.scan(/<div class="[\w_\d\s]+ match_row_alt\d clearfix[_\w\s]* *" id="usr-([\w\d_-]+)">/)
      @c_test       = true if @details.empty?
      @details      ||= html.scan(/<div id="usr-([\w\d_-]+)-wrapper" class="match_card_wrapper user-not-hidden ">/)
      html_doc = Nokogiri::HTML(html)
      @gender, @age, @state, @city     = {}

      @details.each do |user|
        result2 = html_doc.xpath("//div[@id='usr-#{user[0]}-wrapper']").to_s
        age = result2.match(/span.class=.age.>(\d{2})/)[1].to_i

        result2     ||= html_doc.xpath("//div[@id='usr-#{user[0]}']").to_s
        age         ||= result2.match(/span.class=.age.>(\d{2})/)[1].to_i
        gender        = $gender
        username      = user[0].to_s
        puts "username: #{username}, age: #{age}, gender: #{gender}"  if $debug
        city, state   = String.new
        location      = /location.>(.+)<.span>/.match(result2)[1].to_s
        begin
          city        = RegEx.parsed_location(location)[:city]
          state       = RegEx.parsed_location(location)[:state]
        rescue
          puts location
        end
        puts "city: #{city}, state: #{state}" if $debug
        # match_percent = /(\d+)%<.span> Match/.match(result2)[1] if b_test
        match_percent = /(\d+)% Match/.match(result2)[1]# unless b_test
        puts "#{username} #{match_percent}% match" if $debug
        @db.add(username: username, gender: gender, added_From: "ajax_match_search", age: age, city: city, state: state, match_percent: match_percent, age: age)
      end
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
      @most_recent_message_id = IncomingMessage.where(:account => $login).exclude(:username => nil).order(Sequel.desc(:timestamp)).first.to_hash[:message_id] rescue 0
      @inbox_up_to_date = false
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
      unless @total_msg == @prev_total_messages || @inbox_up_to_date
        low = 1
        extract_messages_from_page(low)
        # break if @inbox_up_to_date
        if @total_msg > 0
          puts "#{@total_msg - @prev_total_messages} new messages..."
        else
          @total_msg = @total_msg_on_page
        end
        unless @inbox_up_to_date
          until low >= @total_msg || @inbox_up_to_date
            low += 30
            extract_messages_from_page(low)
            sleep (1..6).to_a.sample.to_i
          end
        end
        @prev_total_messages = @total_msg
      end
    end

    def extract_messages_from_page(low)
      # delete_mutual_matches(msg_page)
      result = async_response("http://www.okcupid.com/messages?low=#{low}&infiniscroll=1&folder=1")

      message_list = result[:body].scan(/"message_(\d+)"/)
      @total_msg_on_page = message_list.size
      unless @total_msg_on_page == 0
        unless message_list.include?(@most_recent_message_id)
          message_list.each do |message_id|
            message_id      = message_id.first
            if message_id == @most_recent_message_id
              @inbox_up_to_date = true
              break
            end
            msg_block       = result[:html].parser.xpath("//li[@id='message_#{message_id}']").to_html
            # unless !(msg_block =~ /"subject">OKCupid!</).nil?
            sender          = /\/([\w\d_-]+)\?cf=messages/.match( msg_block)[1]
            timestamp       = msg_block.match(/(\d{10}), 'BRIEF/)[1].to_i
            sender          = sender.to_s
            register_message(sender, timestamp, message_id)
            # inbox_cleanup(msg_page)

          end
        else
          puts "Inbox up to date!"
        end
      else
        puts "No more messages"
      end
    end

    def register_message(sender, timestamp, message_id)

      # [todo] - add messages table to db
      # [todo] - register message with timestamp, account, sender, and message id
      # [todo] - check to see if this message is unique/new

      # @stored_time     = @db.get_last_received_message_date(sender).to_i
      if timestamp.to_i >= Time.now.to_i - 1800
        puts "New message from #{sender}"
      end

      puts "Registering message #{message_id}"
      @db.ignore_user(sender)
      # @db
      # @db.add_user(username: sender, gender: gender, added_From: "inbox", ignored: true)

      @db.add_message(username: sender, message_id: message_id, timestamp: timestamp)
    end

    def scrape_im_page
      puts "Scraping IM page" if $verbose
      result = async_response("http://www.okcupid.com/imhistory")
    end
  end
end
