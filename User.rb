class Users
  attr_reader :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked
  attr_accessor :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked

  def initialize
    @match_percentage = Hash.new(0)
    @age = Hash.new(0)
    @count = Hash.new(0)
    @city = Hash.new(0)
    @sexuality = Hash.new(0)
    @gender = Hash.new(0)
    @relationship_status = Hash.new(0)
  end

def handle
  @handle
end

def match_percentage
  @match[@handle]
end

def age
  @age[@handle]
end

def count
  @names[@handle]
end

def city
  @city[@handle]
end

def sexuality
  @sexuality[@handle]
end

def gender
  @gender[@handle]
end

def relationship_status
  @relationship_status[@handle]
end

def is_blocked
  @is_blocked[@handle]
end



end