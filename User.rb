class Users
  attr_reader :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked
  attr_accessor :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked

  def initialize(args)
    @db = args[ :database]
    @browser = args[ :browser]
    @match_percentage = Hash.new(0)
    @age = Hash.new(0)
    @count = Hash.new(0)
    @city = Hash.new(0)
    @sexuality = Hash.new(0)
    @gender = Hash.new(0)
    @relationship_status = Hash.new(0)
  end

def handle
  @body.match(/href="\/profile\/([\w\d]+)\/photos"/)[1]
end


def match_percentage
  @body.match(/"match"\>\<strong>(\d+)\%\<\/strong\> Match\<\/p\>/)[1]
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