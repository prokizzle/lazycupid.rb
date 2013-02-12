

class BlockList
  attr_accessor :ignore_list, :is_ignored
  attr_reader :ignore_list, :is_ignored

  def initialize(args)
    @database = args[ :database]
    @ignore_list = @database.ignore
    process_ignore_list
  end

  def process_ignore_list
    @ignore_list.each do |user, value|
      if value == false
        @ignore_list.delete(user)
      end
    end
  end

  def ignore_user(match)
    @ignore_list[match] = true
  end

  def save
    @temp = @database.ignore
    @temp.each do |user, value|
      if @ignore_list[user] != value
        @temp[user] = value
      end
    end
    @database.ignore = @temp
  end

  def is_ignored (user)
    (@ignore_list.has_key?(user))
  end

end
