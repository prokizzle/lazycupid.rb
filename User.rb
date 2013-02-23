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
    /(\d{2}) \/ (F|M) \/ (Straight|Bisexual|Gay) \/ (Single|Seeing someone|Available|Married) \/ (.+)\s<\/p>/.match(body)
  end

  def handle
    body.match(/href="\/profile\/([A-z0-9_-]+)\/photos"/)[1]
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

  def location
    asl[5]
  end

  def city
    begin
      location.match(/(\w[\w\s]+),/)[1]
    rescue
      "Invalid"
    end
  end

  def state
    begin
      location.match(/, (\w[\w\s]+)/)[1]
    rescue
      "Invalid"
    end
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
