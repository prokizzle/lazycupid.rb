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
    result = @browser.current_user.parser.xpath("//span[@id='ajax_age']").to_html
    age = />(\d{2})</.match(result)[1]
    age.to_i
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
    # /smoking.>(.*)<.dd>/.match(body)[1].to_s
    result = @browser.current_user.parser.xpath("//dd[@id='ajax_smoking']").to_html
    smoking = />(.*)</.match(result)[1]
    smoking.to_s

  end

  def drinking
    # /drinking.>(.+)<.dd>/.match(body)[1].to_s
    result = @browser.current_user.parser.xpath("//dd[@id='ajax_drinking']").to_html
    new_result = />(.*)</.match(result)[1]
    new_result.to_s
  end

  def drugs
    /drugs.>(.+)<\/dd>/.match(body)[1].to_s
  end

  def kids
    /children.>(.+)<\/dd>/.match(body)[1].to_s
  end

  def last_online
    begin
      result = /(\d{10}),..JOURNAL_FORMAT./.match(body)[1].to_i
      result
    rescue
      Time.now.to_i if body.match(/Online now\!/)
    end
  end

  def count
    @names[@handle].to_i
  end

  def location
    result = @browser.current_user.parser.xpath("//span[@id='ajax_location']").to_html
    location = />(.*)</.match(result)[1]
    location.to_s
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
      location.match(/, (.*)/)[1].to_s
    rescue
      "Invalid"
    end
  end

  def foreign_locations
    delims = location.scan(/(.*),/)
    counter
    delims.each do |item|
      counter += 1
    end
    if counter > 2
      @city = delims[1]
      @state = delims[2]
      @country = delims[3]
    end
  end


  def sexuality
    result = @browser.current_user.parser.xpath("//span[@id='ajax_orientation']").to_html
    sexuality = />(Straight|Bisexual|Gay)</.match(result)[1]
    sexuality.to_s
  end

  def gender
    result = @browser.current_user.parser.xpath("//span[@id='ajax_gender']").to_html
    gender = />(M|F)</.match(result)[1]
    gender.to_s
  end

  def relative_distance
    begin
      /\((\d+) miles*\)/.match(body)[1].to_i
    rescue
      1
    end
  end

  def relationship_status
        result = @browser.current_user.parser.xpath("//span[@id='ajax_status']").to_html
        new_result = />(.*)</.match(result)[1]
        new_result.to_s
  end

  def is_blocked
    @db.is_ignored(handle)
  end

end