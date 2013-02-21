class Users
  attr_reader :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked
  attr_accessor :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked

  def initialize(args)
    @db = args[ :database]
    @browser = args[ :browser]
  end

  def body
    @browser.body
  end

  def asl
    /(\d{2}) \/ (F|M) \/ (Straight|Bisexual|Gay) \/ (Single|Seeing Someone|Available) \/ (\w+), (\w+)/.match(body)
  end

  def handle
    /messages\?r1\=([\w\d]+)/.match(body)
  end

  def match_percentage
    body.match(/"match"\>\<strong>(\d+)\%\<\/strong\> Match\<\/p\>/)[1]
  end

  def age
    asl[1]
  end

  def count
    @names[@handle]
  end

  def city
    asl[5]
  end

  def state
    asl[6]
  end

  def sexuality
    asl[3]
  end

  def gender
    asl[2]
  end

  def relationship_status
    asl[4]
  end

  def is_blocked
    @db.is_ignored(handle)
  end



end
