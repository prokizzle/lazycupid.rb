require 'rubygems'
require 'progress_bar'

class Harvester
  attr_reader :type, :number
  attr_accessor :type, :number
  def initialize(args)
    @browser = args[ :browser]
    @database = args[ :database]
    @scrape_queue = Array.new
    @visitor_counter = @database.visit_count
    @visitor_tracker = @database.zindex
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
    for i in 0..number do
      @bar.increment!
      scrape_from_page(url)
      sleep 1
    end
    self.save
  end

  def number
    @number
  end

  def scrape_from_page(url)
    @browser.go_to(url)
    @body = @browser.body
    self.leftbar_scrape
  end

  def save
    @database.zindex = @visitor_tracker
    @database.visit_count = @visitor_counter
    @database.save
  end

  def leftbar_scrape
    array = @body.scan(/href="\/profile\/([\w\d]+)\?leftbar\_match\=1"/)
    array.each do |users|
      users.each do |user|
        @database.add_new_match(user)
      end
    end
  end

  def visitors
    @browser.go_to("http://www.okcupid.com/visitors")
    @current_user = @browser.current_user
    @visitors = @current_user.parser.xpath("//div[@id='main_column']").to_html
    array = @visitors.scan(/"usr-([\w\d]+)".+z\-index\:\s(\d\d\d)/)
    array.each do |visitor, zindex|
      @timestamp_block = @current_user.parser.xpath("//div[@id='usr-#{visitor}-info']/p/span[@class='fancydate']").to_html
      @timestamp = @timestamp_block.match(/\d+/)[1]
      if @visitor_tracker[visitor].to_i != @timestamp
        @visitor_counter[visitor] = @visitor_counter[visitor].to_i + 1
        puts "New visit from #{visitor}"
      end
      @visitor_tracker[visitor] = @timestamp
    end
    sleep 1
    self.save
  end
end
