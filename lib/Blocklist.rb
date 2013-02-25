

class BlockList
  attr_accessor :is_ignored, :add, :remove
  attr_reader :is_ignored, :add, :remove

  def initialize(args)
    @database = args[ :database]
    @browser = args[ :browser]
    # @ignore_list = @database.ignore
    # process_ignore_list
    # self.import_hidden_users
  end

  def user_exists(match)
    @database.existsCheck(match)
  end

  def add(match)
    @database.ignore_user(match) if user_exists(match)
  end

  def remove(match)
    @database.unignore_user(match) if user_exists(match)
  end

  def is_ignored (user)
    (@database.is_ignored(user))
  end

  def body
    @browser.body
  end

  def scrape_users
    hidden_users = body.scan(/"\/profile\/([\d\w]+)"/)
    hidden_users.each do |array|
      array.each do |user|
        unless is_ignored(user)
          self.add(user)
        end
      end
    end
  end

  def import_hidden_users
    @browser.go_to("http://www.okcupid.com/hidden-users")
    self.scrape_users
    until body.match(/next inactive/)
      low = body.match(/hidden-users\?low\=(\d+).+Next/)[1]
      puts low
      @browser.go_to("http://www.okcupid.com/hidden-users?low=#{low}")
      self.scrape_users
      sleep 2
    end
  end
end
