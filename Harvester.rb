require 'rubygems'
require 'progress_bar'

class Harvester
  attr_reader :type, :number
  attr_accessor :type, :number
  def initialize(args)
    @browser = args[ :browser]
    @database = args[ :database]
    @scrape_queue = Array.new
  end

  def run
    puts "Harvesting"
    self.get_batch(@number)
  end

  def safety_dance(method)
    begin
      method.call
    rescue SystemExit, Interrupt
    end
  end


  def get_batch(number, url="http://www.okcupid.com/messages")
    @bar = ProgressBar.new(number)
    for i in 0...number do
      @bar.increment!
      scrape_from_page(url)
      sleep 1
    end
  end

  def number
    @number
  end

  def scrape_from_page(url)
    @browser.go_to(url)
    @body = @browser.body
    self.leftbar_scrape
  end

  def leftbar_scrape
    array = @body.scan(/href="\/profile\/([\w\d]+)\?leftbar\_match\=1"/)
    array.each do |users|
      users.each do |user|
        @database.add_user(user)
      end
    end
  end

  def similar_user_scrape(match)
    # @found = Array.new
    @database.log(match)
    @browser.go_to("http://www.okcupid.com/profile/#{match}")
    @body = @browser.body
    array = @body.scan(/href="\/profile\/([\w\d]+)\?cf\=profile\_similar"/)
    # array.each do |users|
    #   array.each do |user|
    #     @browser.go_to("http://www.okcupid.com/profile/#{match}")
    #     @body = @browser.body
    #     array = @body.scan(/href="\/profile\/([\w\d]+)\?cf\=profile\_similar"/)
    #     array.each do |finds|
    #       array.each do |find|
    #         @found += [find]
    #       end
    #     end
    #   end
    # end

    # @found.each do |finder|
    #   @database.add_new_match(finder)
    # end

    array.each do |users|
      users.each do |user|
        @database.add_user(user)
      end
    end
  end

  def increment_visitor_counter(visitor)
    original = @database.get_visitor_count(visitor)
    new_counter  = original + 1
    @database.set_visitor_counter(visitor, new_counter)
  end

  def visitors
    @browser.go_to("http://www.okcupid.com/visitors")
    @current_user = @browser.current_user
    @visitors = @current_user.parser.xpath("//div[@id='main_column']").to_html
    array = @visitors.scan(/"usr-([\w\d]+)".+z\-index\:\s(\d\d\d)/)
    array.each do |visitor, zindex|
      @timestamp_block = @current_user.parser.xpath("//div[@id='usr-#{visitor}-info']/p/span[@class='fancydate']").to_html
      @timestamp = @timestamp_block.match(/\d+/)[0]
      if @database.get_visitor_timestamp(visitor) != @timestamp.to_i
        self.increment_visitor_counter(visitor)
        puts "New visit from #{visitor}"
        puts "Timestamp: #{@timestamp} & Stored: #{@database.get_visitor_timestamp(visitor)}"
      end
      @database.set_visitor_timestamp(visitor, @timestamp)
    end
    sleep 1
  end
end
