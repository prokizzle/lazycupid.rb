require 'rubygems'
require 'progress_bar'

class Harvester
  attr_reader :type, :number
  attr_accessor :type, :number

  def initialize(args)
    @browser = args[ :browser]
    @database = args[ :database]
    @user = args[ :user_stats]
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

    def body
      @browser.body
    end

    def scrape_from_page(url)

      self.leftbar_scrape(url)
    end

    def scrape_from_user
      self.leftbar_scrape
      self.similar_user_scrape
    end

    def leftbar_scrape
      # @browser.go_to(url)
      array = body.scan(/href="\/profile\/([\w\d]+)\?leftbar\_match\=1"/)
      array.each do |users|
        users.each do |user|
          @database.add_user(user, 0)
        end
      end
    end

    def similar_user_scrape
      # @found = Array.new
      # @database.log(match)
      # @browser.go_to("http://www.okcupid.com/profile/#{match}")
      @body = @browser.body
      array = @body.scan(/href="\/profile\/([\w\d]+)\?cf\=profile\_similar"/)
      array.each do |users|
        users.each do |user|
          @database.add_user(user, 0) if @user.gender == "F"
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
      @genders = @visitors.scan(/>([\w\d]+).+\d{2} \/ (F|M) /)
      @gender = Hash.new(0)

      @genders.each do |user, gender|
        @gender[user] = gender
      end

      array = @visitors.scan(/"usr-([\w\d]+)".+z\-index\:\s(\d\d\d)/)
      array.each do |visitor, zindex|
        @timestamp_block = @current_user.parser.xpath("//div[@id='usr-#{visitor}-info']/p/script/text()").to_html
        @timestamp = @timestamp_block.match(/(\d{10}), 'JOU/)[1].to_i
        @stored_timestamp = @database.get_visitor_timestamp(visitor).to_i

        if !(@stored_timestamp == @timestamp)
          self.increment_visitor_counter(visitor)
          puts "New visit from #{visitor}" if (@gender[visitor] == "F")
          # puts "Timestamp: #{@timestamp} & Stored: #{@database.get_visitor_timestamp(visitor)}"
          if (@gender[visitor]=="F")
            @database.add_user(visitor, 0)
            @database.set_gender(visitor, "F")
          else
            puts "Ignoring man named #{visitor}"
            @database.ignore_user(visitor)
            @database.set_gender(visitor, "M")
          end
        end

        @database.set_visitor_timestamp(visitor, @timestamp.to_i)


        # sleep 1
      end
    end
  end
