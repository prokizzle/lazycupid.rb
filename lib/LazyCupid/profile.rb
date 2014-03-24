# encoding: utf-8

module LazyCupid

  # OKCupid profile page parser
  # Class methods for turning a scraped Mechanize page for an OKCupid user profile
  # into a hash of attributes for easy data manipulation and storage.
  #
  class Profile
    require_relative 'text_classifier'
    require 'lingua'

    attr_reader :verbose, :debug, :body, :url, :html, :intended_handle, :new_handle

    public

    def self.initialize
      # $verbose  = true
      # @debug    = true
    end

    # Parses a profile page for user attributes
    #
    # @param user_page [Hash] [A browser request hash containing body, url, and Mechanize page object]
    # @return [Hash] a hash of attributes scraped from the profile page
    #
    def self.parse(user_page)

      # [todo] - separate response hashes into match & user specific table data
      @new_handle = nil
      @body = user_page[:body].encode!('UTF-16', 'UTF-8', :invalid => :replace, :replace => '').encode!('UTF-8', 'UTF-16')
      @html = user_page[:html]
      @source = user_page[:source]
      url = user_page[:url]
      # begin
      inactive = !(@body =~ $inactive_profile).nil?
      straight = !(@body =~ $straight_person).nil?
      # rescue
      # puts @body
      # end
      @intended_handle = URI.decode(/\/profile\/(.+)/.match(url)[1])
      @readability = Lingua::EN::Readability.new(essays)
      # @analyze = TextClassification.new(read_key: $uclassify_read_key, text: essays)

      # num = @readability.flesch.ceil
      # case num
      # when num > 60 then grade = "middle school"
      # when num 50..59 then grade = "high school"
      # when num 30..49 then grade = "college"
      # when num < 30 then grade = "college grad"
      # else grade = ""
      # end
      # puts grade
      if inactive
        {inactive: true}
      elsif straight
        return {handle: intended_handle,
                sexuality: "Straight"}
      else
        {handle: handle,
         match_percentage: match_percentage,
         age: age,
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
         essays: essays,
         kincaid: kincaid,
         fog: fog,
         flesch: flesch,
         # sentiment: @analyze.sentiment,
         # mood: @analyze.mood(essays),
         # perceived_gender: @analyze.gender(essays),
         # perceived_age: @analyze.age(essays),
         body: @body,
         html: @html }
      end

    end

    private

    # text classification

    def self.kincaid
      return @readability.kincaid.ceil rescue nil
    end

    def self.fog
      score = @readability.fog.ceil rescue nil
      unless score == "NaN"
        return score
      else
        return nil
      end
    end

    def self.flesch
      score = @readability.flesch.ceil rescue nil
      unless score == "NaN"
        return score
      else
        return nil
      end
    end

    # username detection

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
      begin
        # result = @body.match(/<span class="name">([\w\d_-]+)<.span>/)[1]
        result = @html.parser.xpath("//span[@class='name']").text
      rescue Exception => e
        puts e.message
        puts e.backtrace

        puts @body
        # sleep 100
      end
      # end

      unless result == @intended_handle.to_s
        # @db.rename_alist_user(@intended_handle, result)
        @new_handle = result
        puts "(UC) A-list name change: #{intended_handle} is now #{result}" if $verbose
      end

      # puts result
      result.to_s

    end

    # match percentages

    def self.match_percentage
      begin
      result = @source.match(/<span class="percent">(\d+)\%<.span>.<span class="percentlabel">Match<.span>/)[1].to_i
      rescue Exception => e
        result.scan(/percent">([-—\d]+)\%</)[0][0]
      end

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

    def self.enemy_percentage
      # result = @html.parser.xpath("//span[@class='enemy']").text
      begin
        @source.match(/<span class="percent">(\d+)\%<.span>.<span class="percentlabel">Enemy<.span>/)[1].to_i
      rescue
        result.scan(/percent">([-—\d]+)\%</)[1][0]
      end
    end

    def self.slut_test_results
      /(\d+). slut/.match(@body)[1].to_i
    end

    # user details

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
      @html.parser.xpath("//dd[@id='ajax_orientation']").text.split.first
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

    def self.essays
      text = ""
      text += @html.parser.xpath("//div[@id='essay_text_0']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_1']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_2']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_3']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_6']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_7']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_8']").text
      text += " \n" + @html.parser.xpath("//div[@id='essay_text_9']").text
      return text.to_s
    end
  end
end
