require_relative 'DataManager.rb'

class Admin

  def initialize(account, database)
    @account = account
    @db = database
  end

  def add_user(user)
    @db.load
    @db.datas(user, 0)
    @db.log(user)
    @db.save
  end

  def block_user
    #add user to block list or
    #
  end

  def user_exists
    @db.is_valid_user
  end

end

application = Admin.new(ARGV[0], DataReader.new(ARGV[0]))
application.add_user(ARGV[1]) if application.user_exists
puts "Added" if application.user_exists