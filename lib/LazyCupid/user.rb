module LazyCupid
  class Users

    attr_reader :verbose, :debug, :body, :url, :html

    def initialize(args)
      @db = args[ :database]
      @browser  = args[ :browser]
      @log      = args[ :log]
      @path     = args[ :path]
      @verbose  = true
      @debug    = true
    end

    # def verbose
    #   @verbose
    # end

    # def debug
    #   @debug
    # end

    def log
      Logger.new("#{@path}#{@username}_#{Time.now}.log")
    end

    def for_page(page_object)
      @page = page_object
    end

    def profile(user_page)
      @body = user_page[:body]
      @html = user_page[:html]
      # puts @html
      # wait = gets.chomp
      @url = user_page[:url]
      inactive = @body.match(/Uh\-oh/)
      @intended_handle = URI.decode(/\/profile\/(.+)/.match(@url)[1])
      if inactive
        {inactive: inactive}
      else
        {handle: handle,
         match_percentage: match_percentage,
         age: age,
         friend_percentage: friend_percentage,
         enemy_percentage: enemy_percentage,
         # ethnicity: ethnicity,
         height: height,
         # bodytype: body_type,
         # smoking: smoking,
         # drinking: drinking,
         # drugs: drugs,
         # kids: kids,
         last_online: last_online,
         location: location,
         city: city,
         state: state,
         sexuality: sexuality,
         gender: gender,
         distance: relative_distance,
         relationship_status: relationship_status,
         is_blocked: is_blocked,
         intended_handle: @intended_handle,
         inactive: inactive,
         body: @body,
         html: @html }
      end
      
    end

    def display_code
      puts body
      puts "","Press any key..."
      wait = gets.chomp
    end

    def intended_handle
      temp_url = @url
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
      /(\d{2}) \/ (F|M) \/ (Straight|Bisexual|Gay) \/ (Single|Seeing someone|Available|Married|Unknown) \/ (.+)\s<\/p>/.match(@body)
    end

    def handle

      # log = Logger.new("logs/user_test_#{Time.now}.log")
      # log.debug @body
      # begin
      # result = body.match(/username.>([-_\w\d]+)</)[1]
      # result = @html.parser.xpath("//p[@class='username']").text

      # rescue
      # result = /username.>(.+)<.p>.<p.class..info.>/.match(@body)[1]
      result = @body.match(/<div class="userinfo"> <div class="details"> <p class="username">(.+)<.p> <p class="info">/)[1]
      # end

      unless result == @intended_handle.to_s
        @db.rename_alist_user(@intended_handle, result)
        puts "A-list name change: #{intended_handle} is now #{result}" if verbose
      end

      # puts result
      result.to_s

    end

    def match_percentage
      begin
        result = @html.parser.xpath("//span[@class='match']").text
        new_result = /(\d*\d*). Match/.match(result)[1]
        new_result.to_i
      rescue
        log.debug "match_percentage: #{body}"
        begin
          @body.match(/(\d+). Match/)[1].to_i
        rescue
          0
        end
      end
    end

    def friend_percentage
      if />(\d+). Friend.*/.match(@body)
        />(\d+). Friend.*/.match(@body)[1].to_i
      else
        0
      end

    end

    def enemy_percentage
      begin
        />(\d+). Enemy.*/.match(@body)[1].to_i
      rescue
        0
      end
    end

    def slut_test_results
      /(\d+). slut/.match(@body)[1].to_i
    end

    def age
      result = @html.parser.xpath("//span[@id='ajax_age']").text.to_i
    end

    def ethnicity
      /ethnicities.>\s([\w\s]+).*/.match(@body)[1].to_s
    end

    def height
      # hash = Hash.new
      result = @html.parser.xpath("//dd[@id='ajax_height']").text
      begin
        # hash[:meters] =
        /(\d+.\d+)../.match(result)[1].to_f
        # hash[:feet] = /(\d+'\d*"/)/.match(result)[1].to_s
        # {meters: /(\d+.\d+)../.match(result)[1].to_f, feet: /(\d+'\d*"/)/.match(result)[1].to_s}

      rescue
        # {meters: 0, feet: 0}
        0
      end
    end

    def body_type
      /bodytype.>(.+)<.dd>/.match(@body)[1].to_s
    end

    def smoking
      # display_code if debug
      # /smoking.>(.*)<.dd>/.match(@body)[1].to_s
      @html.parser.xpath("//dd[@id='ajax_smoking']").text

    end

    def drinking
      # /drinking.>(.+)<.dd>/.match(@body)[1].to_s
      @html.parser.xpath("//dd[@id='ajax_drinking']").text
    end

    def drugs
      /drugs.>(.+)<\/dd>/.match(@body)[1].to_s
    end

    def kids
      /children.>(.+)<\/dd>/.match(@body)[1].to_s
    end

    def last_online
      begin
        result = /(\d{10}),..JOURNAL_FORMAT./.match(@body)[1].to_i
        result
      rescue
        begin
          Time.now.to_i if body.match(/Online now\!/)
        rescue
        end
      end
    end

    def count
      @names[@handle].to_i
    end

    def location
      @html.parser.xpath("//span[@id='ajax_location']").text
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
      @html.parser.xpath("//span[@id='ajax_orientation']").text
    end

    def gender
      @html.parser.xpath("//span[@id='ajax_gender']").text
    end

    def relative_distance
      begin
        /\((\d+) miles*\)/.match(@body)[1].to_i
      rescue
        1
      end
    end

    def relationship_status
      @html.parser.xpath("//span[@id='ajax_status']").text
    end

    def is_blocked
      @db.is_ignored(handle)
    end

  end
end
