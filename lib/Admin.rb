
class Admin
  attr_reader :menu
  attr_accessor :menu

  def initialize(args)
    @db = args[ :database]
    @account = ""
  end

  def add_user(user)
    @db.add_new_match(user)
  end

  def block_user(user)
    @blocklist.add(user)
  end

  def import
    @db.import
  end

  def user_exists
    @db.is_valid_user
  end


  # application = Admin.new(ARGV[0], DataReader.new(ARGV[0]))
  # application.add_user(ARGV[1]) if application.user_exists
  # puts "Added" if application.user_exists

end
