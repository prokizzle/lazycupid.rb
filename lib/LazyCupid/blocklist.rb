
module LazyCupid
  class BlockList
    attr_accessor :add, :remove
    attr_reader :add, :remove

    def initialize(args)
      @db = args[ :database]
      @browser = args[ :browser]
      # @ignore_list = @database.ignore
      # process_ignore_list
      # import_hidden_users
    end

    def add(match)
      @db.ignore_user(match)
    end

    def remove(match)
      @db.unignore_user(match)
    end

    def body
      @browser.body
    end

    def scrape_users
      hidden_users = @response[:body].scan(/"\/profile\/([\w\d_-]+)"/)
      hidden_users.each { |user| add(user.shift) }
    end

    def import_hidden_users
      request_id = Time.now.to_i
      @response = @browser.body_of("http://www.okcupid.com/hidden-users", request_id)
      @browser.delete_response(request_id)
      # puts @response[:body]
      # sleep 50
      low = 1
      begin
        # pages = @response[:body].match(/<a class="last" href="\/hidden-users\?low=(\d)+">(\d+)<\/a>/)[2].to_i
        total = @response[:body].match(/<a class="last" href="\/hidden-users\?low=(\d+)">(\d+)<\/a>/)[1].to_i
        puts total
      rescue
        puts @response[:body]
      end
      # begin
        scrape_users
        # total = @response[:body].match(/<li><a href="\/hidden-users\?low=(\d+)">\d+<\/a><\/li>\n<li class="next">/)[1].to_i
        puts "Importing #{total} hidden users..."
        # puts @response[:body]
        until low > total
          puts low
          low += 25
          request_id = Time.now.to_i
          @response = @browser.body_of("https://www.okcupid.com/hidden-users?low=#{low}", request_id)
          @browser.delete_response(request_id)
          scrape_users
          sleep 2
        end
      # rescue
        # puts "Finished import."
      # end
    end
  end
end
