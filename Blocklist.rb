

class BlockList
  attr_accessor :is_ignored, :add, :remove
  attr_reader :is_ignored, :add, :remove

  def initialize(args)
    @database = args[ :database]
    # @ignore_list = @database.ignore
    # process_ignore_list
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

end
