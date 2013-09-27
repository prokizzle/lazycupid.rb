module LazyCupid

  # OKCupid profile page parser
  # Class methods for turning a scraped Mechanize page for an OKCupid user profile
  # into a hash of attributes for easy data manipulation and storage.
  # 
  class Profile

    attr_reader :verbose, :debug, :body, :url, :html, :intended_handle, :new_handle

    public 

    def self.initialize
      @verbose  = true
      @debug    = true
    end

    # Parses a profile page for user attributes
    # 
    # @param user_page [Hash] [A browser request hash containing body, url, and Mechanize page object]
    # @return [Hash] a hash of attributes scraped from the profile page
    # 
    def self.parse(user_page)
      @new_handle = nil
      @body = user_page[:body]
      @html = user_page[:html]
      @source = user_page[:source]
      # puts @html
      # wait = gets.chomp
      @url = user_page[:url]
      inactive = @body.match(/we don’t have anyone by that name/)
      @intended_handle = URI.decode(/\/profile\/(.+)/.match(@url)[1])
      if inactive
        {inactive: true}
      else
        {handle: handle,
         match_percentage: match_percentage,
         age: age,
         friend_percentage: friend_percentage,
         enemy_percentage: enemy_percentage,
         ethnicity: ethnicity,
         height: height,
         bodytype: body_type,
         smoking: smoking,
         drinking: drinking,
         drugs: drugs,
         kids: kids,
         last_online: last_online,
         location: location,
         city: city,
         state: state,
         sexuality: sexuality,
         gender: gender,
         distance: relative_distance,
         relationship_status: relationship_status,
         intended_handle: @intended_handle,
         inactive: false,
         a_list_name_change: intended_handle.downcase != handle.downcase,
         new_handle: @new_handle,
         image: profile_picture,
         body: @body,
         html: @html }
      end
      
    end

    private

    def self.intended_handle
      @intended_handle
    end

    def self.new_handle
      @new_handle
    end

    def self.display_code
      puts body
      puts "","Press any key..."
      wait = gets.chomp
    end

    def self.handle

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
        # @db.rename_alist_user(@intended_handle, result)
        @new_handle = result
        puts "(UC) A-list name change: #{intended_handle} is now #{result}" if @verbose
      end

      # puts result
      result.to_s

    end

    def self.match_percentage
      result = @html.parser.xpath("//span[@class='match']").text
      result.match(/(\d+)/)[1].to_i
      # begin
      #   result = @html.parser.xpath("//span[@class='match']").text
      #   new_result = /(\d*\d*). Match/.match(result)[1]
      #   new_result.to_i
      # rescue
      #   log.debug "match_percentage: #{body}"
      #   begin
      #     @body.match(/(\d+). Match/)[1].to_i
      #   rescue
      #     0
      #   end
      # end
    end

    def self.friend_percentage
      result = @html.parser.xpath("//span[@class='friend']").text
      result.match(/(\d+)/)[1].to_i
    end

    def self.enemy_percentage
      result = @html.parser.xpath("//span[@class='enemy']").text
      result.match(/(\d+)/)[1].to_i
    end

    def self.slut_test_results
      /(\d+). slut/.match(@body)[1].to_i
    end

    def self.age
      result = @html.parser.xpath("//span[@id='ajax_age']").text.to_i
    end

    def self.ethnicity
      result = @html.parser.xpath("//dd[@id='ajax_ethnicities']").text
    end

    def self.height
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

    def self.body_type
      @html.parser.xpath("//dd[@id='ajax_bodytype']").text
    end

    def self.smoking
      # display_code if @debug
      # /smoking.>(.*)<.dd>/.match(@body)[1].to_s
      @html.parser.xpath("//dd[@id='ajax_smoking']").text

    end

    def self.drinking
      # /drinking.>(.+)<.dd>/.match(@body)[1].to_s
      @html.parser.xpath("//dd[@id='ajax_drinking']").text
    end

    def self.drugs
      @html.parser.xpath("//dd[@id='ajax_drugs']").text
    end

    def self.kids
      @html.parser.xpath("//dd[@id='ajax_children']").text
    end

    def self.last_online
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

    def self.count
      @names[@handle].to_i
    end

    def self.location
      @html.parser.xpath("//span[@id='ajax_location']").text
    end

    def self.city
      begin
        location.match(/(\w[\w\s]+),/)[1].to_s
      rescue
        "Invalid"
      end
    end

    def self.state
      begin
        location.match(/, (.*)/)[1].to_s
      rescue
        "Invalid"
      end
    end

    def self.foreign_locations
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

    def self.profile_picture
      # @html.parser.xpath("//div[@id='thumb0']/a").href
      nil
    end

    def self.sexuality
      @html.parser.xpath("//span[@id='ajax_orientation']").text
    end

    def self.gender
      @html.parser.xpath("//span[@id='ajax_gender']").text
    end

    def self.relative_distance
      begin
        /\((\d+) miles*\)/.match(@body)[1].to_i
      rescue
        1
      end
    end

    def self.relationship_status
      @html.parser.xpath("//span[@id='ajax_status']").text
    end

    # def self.is_blocked
    #   @db.is_ignored(handle)
    # end

  end
end
