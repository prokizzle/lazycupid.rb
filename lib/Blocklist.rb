

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

  def is_ignored (user)
    (@db.is_ignored(user))
  end

  def body
    @browser.body
  end

  def scrape_users
    hidden_users = body.scan(/"\/profile\/([\d\w]+)"/)
    hidden_users.each { |user| add(user[0]) unless is_ignored(user[0]) }
  end

  def import_hidden_users

    @browser.go_to("http://www.okcupid.com/hidden-users")
    total = body.match(/hidden-users\?low=(\d+)">\d+<.a><.li>\n<li class="next"/)[1].to_i
    # puts body
    bar = ProgressBar.new(total, :counter)
    bar.increment! 1
    scrape_users
    until body.match(/next inactive/)
      low = body.match(/hidden-users\?low\=(\d+).+Next/)[1].to_i
      bar.increment! 25
      @browser.go_to("http://www.okcupid.com/hidden-users?low=#{low}")
      scrape_users
      sleep 2
    end
  end
end
