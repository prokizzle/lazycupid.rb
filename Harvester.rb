require 'rubygems'

class Harvester
  attr_reader :type, :number
  attr_accessor :type, :number
  def initialize(args)
    @browser = args[ :browser]
    @database = args[ :database]
    @scrape_queue = Array.new
    @visitor_ranking = @database.visit_count
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

    for i in 0..number do
      print "=" if i%3==0
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
    @database.zindex = @visitor_ranking
    @database.visit_count = @visitor_tracker
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
      if @visitor_ranking[visitor].to_i < zindex.to_i
        @visitor_tracker[visitor] = @visitor_tracker[visitor].to_i + 1
      end
      @visitor_ranking[visitor] = zindex
    end
    sleep 1
    self.save
  end
end
