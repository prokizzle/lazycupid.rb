require 'mechanize'
require 'json'
# require 'uclassify'

module LazyCupid
  require_relative 'profile'
  class TextClassification

    def initialize(args=[])

      @agent                = Mechanize.new
      @uclassify_read_key   = args[:read_key]



      # @text                 = LazyCupid::Profile.parse(resp)[:essays]

    end

    # def gender(text)
    #   content = URI.escape(text)
    #   f = @agent.get("http://uclassify.com/browse/uClassify/GenderAnalyzer_v5/ClassifyText?readkey=#{$uclassify_read_key}&text=#{content}&output=json&version=1.01")
    #   reading = JSON.parse(f.content).to_hash["cls1"]
    #   puts reading
    #   return reading["female"] > reading["male"] ? "female" : "male"
    #   # return JSON.parse(result.gsub('\"', '\'')).to_hash
    # end

    private

    def result(owner, classifier, text)
      content = URI.escape(text)
      f = @agent.get("http://uclassify.com/browse/#{owner}/#{classifier}/ClassifyText?readkey=#{@uclassify_read_key}&text=#{content}&output=json&version=1.01")
      reading = JSON.parse(f.content).to_hash["cls1"]
      begin
        max = reading.values.max
        h = Hash[reading.select { |k, v| v == max}]
        return h.keys
      rescue
        return f.content
      end
    end

    public

    def fetch(target, data)
      @text = LazyCupid::Profile.parse(data)[:essays]
      send(target)
    end

      def gender(text = @text)
        result("uClassify", "GenderAnalyzer_v5", text)
      end

      def mood(text = @text)
        return result("prfekt", "Mood", text)
      end

      def values(text = @text)
        return result("prfekt", "Values", text)
      end

      def sentiment(text = @text)
        result("uClassify", "Sentiment", text)

      end

      def topics(text = @text)
        result("uClassify", "Topics", text)

      end

      def society(text = @text)
        result("uClassify", "Society_Topics", text)

      end

      def classics(text = @text)
        result("uClassify", "classics", text)
      end

      def age(text = @text)
        result("uClassify", "Ageanalyzer", text)

      end

      def mb_attitude(text = @text)
        result("prfekt", "Myers_Briggs_Attitude", text)

      end

      def mb_perceiving(text = @text)
        result("prfekt", "Myers_Briggs_Perceiving", text)
      end

      def mb_judging(text = @text)
        result("prfekt", "Myers_Briggs_Judging", text)
      end

      def mb_lifestyle(text = @text)
        result("prfekt", 'Myers_Briggs_Lifestyle', text)
      end

      def emo(text=@text)
        result("saifer", "emo", text)
      end



      def myers_briggs(text = @text)
        return "#{mb_attitude(text)}#{mb_perceiving(text)}#{mb_judging(text)}#{mb_lifestyle(text)}"
      end





      def run
        puts mood(@text)
        puts gender(@text)
        puts sentiment(@text)
        puts topics(@text)
        puts age(@text)
        puts values(@text)

        puts classics(@text)
        # puts society(@text)
      end

    end
  end

  require_relative 'browser'
  require 'highline/import'

  username = ask("username: ")
  password = ask("password: "){ |q| q.echo = "*" }
  rk = "***REMOVED***"

  t = LazyCupid::TextClassification.new(read_key: rk)
  b = LazyCupid::Browser.new(username: username, password: password)
  b.login
  loop do
    puts ""
  user = ask("user: ")
  url = "http://www.okcupid.com/profile/#{user}"

  browser               = b
  request_id            = (1..266).to_a.sample

  browser.send_request(url, request_id)

  print "Requesting profile..."
  resp = {ready: false}
  until resp[:ready] == true
    resp = browser.get_request(request_id)
    # p resp
  end
  puts " done."


  mood = t.fetch("mood", resp).first
  gender = t.fetch("gender", resp).first
  sentiment = t.fetch("sentiment", resp).first
  topics = t.fetch("topics", resp).first
  age = t.fetch("age", resp).first
  values = t.fetch("values", resp).first
  classics = t.fetch("classics", resp).first
  he = gender == "female" ? "she" : "he".first
  his = gender == "female" ? "her" : "his"
  emo = t.fetch("emo", resp)

  print "#{user} is a #{values} #{gender}, "
  print "who values #{topics}, is generally #{sentiment}, "
  print "was #{mood} when #{he} wrote #{his} profile, "
  puts "acts like #{he} is #{age} and writes like #{classics}"
  puts "emo: #{emo}"
end
