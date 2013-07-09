
module LazyCupid
  class BlockList
    attr_accessor :is_ignored, :add, :remove
    attr_reader :is_ignored, :add, :remove

    def initialize(args)
      @db = args[ :database]
      @browser = args[ :browser]
      # @ignore_list = @database.ignore
      # process_ignore_list
      # import_hidden_users
    end

    def user_exists(match)
      @db.existsCheck(match)
    end

    def add(match)
      @db.ignore_user(match) if user_exists(match)
    end

    def remove(match)
      @db.unignore_user(match) if user_exists(match)
    end

    def is_ignored (user, gender)
      (@db.is_ignored(user, gender))
    end

    def body
      @browser.body
    end

    def scrape_users
      hidden_users = @response[:body].scan(/"\/profile\/([\d\w]+)"/)
      hidden_users.each { |user| add(user.shift) }
    end

    def import_hidden_users

      @response = @browser.body_of("http://www.okcupid.com/hidden-users", Time.now.to_i)
      # puts @response[:body]
      # sleep 50
      low = 25
      begin
        pages = @response[:body].match(/>(\d+)<\/a><\/li>\n<li class="next"/)[1].to_i
      rescue
        puts @response[:body]
      end
      begin
        scrape_users
        total = @response[:body].match(/<li><a href="\/hidden-users\?low=(\d+)">\d+<\/a><\/li>\n<li class="next">/)[1].to_i
        puts "Importing #{total} hidden users..."
        # puts @response[:body]
        until low > total
          low += 25
          @response = @browser.body_of("http://www.okcupid.com/hidden-users?low=#{low}", Time.now.to_i)
          scrape_users
          sleep [2,3,4,5,6].sample
        end
      rescue
        puts "Finished import."
      end
    end
  end
end