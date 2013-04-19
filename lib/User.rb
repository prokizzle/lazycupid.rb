class Users

  attr_reader :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked
  attr_accessor :handle, :match_percentage, :age, :count, :sexuality, :gender, :relationship_status, :is_blocked

  def initialize(args)
    @db = args[ :database]
    @browser  = args[ :browser]
    @log      = args[ :log]
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
    temp_url = @browser.url
    begin
      /\/profile\/(.+)/.match(temp_url)[1]
    rescue Exception => e
      @log.debug "#{temp_url}"
      @log.debug body
      @log.debug "#{e.message}"
      @log.debug "#{e.backtrace}"
    end
  end

  def asl
    /(\d{2}) \/ (F|M) \/ (Straight|Bisexual|Gay) \/ (Single|Seeing someone|Available|Married|Unknown) \/ (.+)\s<\/p>/.match(body)
  end

  def handle

    begin
      # result = body.match(/username.>([-_\w\d]+)</)[1]
      result = @browser.current_user.parser.xpath("//span[@id='basic_info_sn']").text
    rescue
      result = /username.>(.+)<.p>.<p.class..info.>/.match(body)[1]
    end

    unless result == intended_handle
      @db.rename_alist_user(intended_handle, result)
      puts "A-list bug: #{intended_handle} is now #{result}" if verbose
    end

    result.to_s

  end

  def match_percentage
    result = @browser.current_user.parser.xpath("//span[@class='match']").text
    new_result = /(\d+)/.match(result)[1]
    new_result.to_i
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
    result = @browser.current_user.parser.xpath("//span[@id='ajax_age']").text.to_i
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
    @browser.current_user.parser.xpath("//dd[@id='ajax_smoking']").text

  end

  def drinking
    # /drinking.>(.+)<.dd>/.match(body)[1].to_s
    @browser.current_user.parser.xpath("//dd[@id='ajax_drinking']").text
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
    @browser.current_user.parser.xpath("//span[@id='ajax_location']").text
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
    @browser.current_user.parser.xpath("//span[@id='ajax_orientation']").text
  end

  def gender
    @browser.current_user.parser.xpath("//span[@id='ajax_gender']").text
  end

  def relative_distance
    begin
      /\((\d+) miles*\)/.match(body)[1].to_i
    rescue
      1
    end
  end

  def relationship_status
    @browser.current_user.parser.xpath("//span[@id='ajax_status']").text
  end

  def is_blocked
    @db.is_ignored(handle)
  end

end
