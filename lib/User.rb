class Users
  attr_reader :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked
  attr_accessor :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked

  def initialize(args)
    @db = args[ :database]
    @browser  = args[ :browser]
    @verbose  = true
    @debug    = true
  end

  def body
    @browser.body
  end

  def verbose
    @verbose
  end

  def debug
    @debug
  end

  def display_code
    puts body
    puts "","Press any key..."
    wait = gets.chomp
  end

  def intended_handle
    @browser.handle
  end

  def asl
    /(\d{2}) \/ (F|M) \/ (Straight|Bisexual|Gay) \/ (Single|Seeing someone|Available|Married|Unknown) \/ (.+)\s<\/p>/.match(body)
  end

  def handle

    begin
      result = body.match(/username.>([-_\w\d]+)</)[1]
    rescue
      result = /username.>(.+)<.p>.<p.class..info.>/.match(body)[1]
    end

    unless result == intended_handle
      @db.delete_user(intended_handle)
      puts "A-list bug: #{intended_handle} is now #{result}" if verbose
    end

    result

  end

  def match_percentage
    />(\d+). Match.*/.match(body)[1].to_i
  end

  def friend_percentage
    />(\d+). Friend.*/.match(body)[1].to_i
  end

  def enemy_percentage
    />(\d+). Enemy.*/.match(body)[1].to_i
  end

  def slut_test_results
    /(\d+). slut/.match(body)[1].to_i
  end

  def age
    asl[1].to_i
  end

  def ethnicity
    /ethnicities.>\s([\w\s]+).*/.match(body)[1].to_s
  end

  def height
    /height.>.+\(*([\d\.]*)m*/.match(body)[1].to_f
  end

  def body_type
    /bodytype.>(.+)<.dd>/.match(body)[1].to_s
  end

  def smoking
    # display_code if debug
    /smoking.>(.+)<.dd>/.match(body)[1].to_s
  end

  def drinking
    /drinking.>(.+)<.dd>/.match(body)[1].to_s
  end

  def drugs
    /drugs.>(.+)<\/dd>/.match(body)[1].to_s
  end

  def kids
    /children.>(.+)<\/dd>/.match(body)[1].to_s
  end

  def count
    @names[@handle].to_i
  end

  def location
    asl[5].to_s
  end

  def city
    begin
      location.match(/(\w[\w\s]+),/)[1].to_s
    rescue
      "Invalid"
    end
  end

  def state
    begin
      location.match(/, (\w[\w\s]+)\s/)[1].to_s
    rescue
      "Invalid"
    end
  end

  def sexuality
    asl[3].to_s
  end

  def gender
    asl[2].to_s
  end

  def relative_distance
    begin
      /\((\d+) miles*\)/.match(body)[1].to_i
    rescue
      1
    end
  end

  def relationship_status
    asl[4].to_s
  end

  def is_blocked
    @db.is_ignored(handle)
  end



end
