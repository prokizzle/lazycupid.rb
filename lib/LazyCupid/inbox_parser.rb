require 'uuidtools'

module LazyCupid

  class InboxScraper

    def async_response(url)
      result = {ready: false}
      request_id = UUID.create_timestamp
      @browser.send_request(url, request_id)
      until result[:ready] == true
        result = @browser.get_request(request_id)
      end
      @browser.delete_response(request_id)
      return result
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

    def parse_inbox_page(url)
      result = async_response(url)
      message_list = result[:body].scan(/id\="message_(\d+)"/)
      message_list.each do |id|
        thread = result[:html].parser.xpath("//li[@id='message_#{id[0]}']")
        info = thread.to_html.match(/([-\w\d_]+)\?cf=messages..class="photo">.+src="(.+)" border.+threadid.(\d+).+fancydate_\d+.. (\d+),/)
        @messages.push({handle: info[1], photo_thumbnail: info[2], thread_id: info[3], thread_url: "http://www.okcupid.com/messages?readmsg=true&threadid=#{info[3]}&folder=1", message_date: info[4]})
      end
    end

    def scrape_inbox
      puts "Scraping inbox" if verbose
      result = async_response("http://www.okcupid.com/messages")
      begin
        @total_msg    = result[:body].match(/"pg_total.>(\d+)</)[1].to_i
      rescue
        @total_msg    = 0
      end
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

    def register_message(sender, timestamp, gender)
      # @stored_time     = @db.get_last_received_message_date(sender).to_i
      puts "New message from #{sender}"

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
  end
end
