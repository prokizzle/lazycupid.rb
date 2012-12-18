require 'rubygems'
require 'mechanize'
require 'csv'
require 'sequel'
# require 'sqlite3'
# require 'set'
require_relative 'OutputScrape.rb'

class AutoRoller

  attr_accessor :names
  attr_accessor :username

  def intitialize(user,pass,speed)
    @username = user
    @password = pass
    @max = m
    @speed = speed
    @ignore = Hash.new(0)
    loadIgnoreList

  end


  def clear
    print "\e[2J\e[f"
  end

  def formatter(a, b, c, d)
    clear
    puts "",""
    puts "        LazyCupid Ruby","     ========================="
    puts "        AutoRoller @ #{d} MPH","       ----------------------"
    puts "         For: #{@username}",""
    puts "          Visiting: #{a}"
    puts "          Match:    #{b}%"
    puts "          Visits:   #{c}"
  end


  def saveData(names)
    print "Saving..."

    @storeCounts.clear
    @names.each do |a, b|
      row = [a, b]
      # puts "--------------"
      # print a.to_s + ", ".to_s
      # print b
      @storeCounts.data = row
      @storeCounts.append
      # puts row
    end
    print " Done.\n"
  end

  def lastVisited(match_name)
    CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
      text = row[0]
      if text == match_name
        @date = row[2].to_s

      else

        @date = "N/a"
      end
    end

    puts @date
  end

  def newUser
    begin
      CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
        puts ""
      end
    rescue
      puts "Setting up new user"
      @saveResults.clear
      @storeCounts.clear
    end
  end

  def loadData
    @names = Hash.new {|h, k| h[k] = 0 }
        puts "Loading data file"
        CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
          text = row[0]
          count = row[1].to_i
          @names[text] = count
        end
  end


  def importCSV(user)
    print "Importing..."
    c = 0
    @names = Hash.new {|h, k| h[k] = 0 }
    CSV.foreach(user.to_s + ".csv", :headers => true, :skip_blanks => true) do |row|

      text = row[0]
      if defined? @names[text]
        c += 1
        @names[text] = (@names[text].to_i + 1)

      end
      # puts puts text + ": " + names[text].to_s
    end
    print " Done.\n"
    saveData(@names)
  end

  def tallyVisit(name, match)
    # puts "Tally Debug:"
    # puts @names[name]
    row = [name.to_s,match.to_s, Time.now, Time.now.to_i]
    @saveResults.data = row
    @saveResults.append
    # @names[name] = (@names[name].to_i + 1).to_s
    @names[name] = (@names[name] + 1)
    # puts @names[name]
  end

  def login(user, pass)
    puts "Logging in..."
    begin
      @username = user
      @password = pass
      @saveResults = OutputScrape.new
      @saveResults.file = @username + ".csv"
      @storeCounts = OutputScrape.new
      @storeCounts.file = @username + "_count.csv"
      @log = Hash.new
      @agent = Mechanize.new
      # @agent.user_agent_alias = 'Mac Safari'
      page = @agent.get("https://www.okcupid.com/")
      # link = page.link_with(:text=>"CUSTOMER LOGIN")
      # page = link.click
      form = page.forms.first
      form['username']=@username
      form['password']=@password
      page = form.submit
      sleep 10
      puts "Logged in as: " + @username.to_s
      newUser
      # Regex to see if logged in
    rescue Exception => e
      puts e.backtrace
      puts "Invalid password. Please try again"
      print "Username: "
      @username = gets.chomp
      print "Password: "
      @password = gets.chomp
    end
  end

  def ignoreUser(match)
    if !(defined? @ignore)
      @ignore = Hash.new(0)
    end
    @ignoreList = OutputScrape.new
    # @ignoreList.clear
    @ignoreList.file = @username + "_ignore.csv"
    @ignoreList.data = [match]
    @ignoreList.append
    @ignore[match] = true
  end


  def loadIgnoreList
    begin
      @ignore = Hash.new(0)
      CSV.foreach(@username + "_ignore.csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        @ignore[text] = true
      end
    rescue
      ignoreUser(@username)
    end

  end

  def checkIgnore? (user)
    (@ignore[user] == true)
  end

  def getCounts(match)
    return @names[match]
  end

  # def toDatabase
  #   CSV.foreach(@username + ".csv", :headers => true) do |row|
  #     DartaBase.create!(row.to_hash)
  #   end
  # end

  def printDB
    matches = @db[:matches]
    matches.each{|row| puts row}
  end

  def getUserId(user)
    return ids[user]
  end

  def setUserIds
    @ids = Hash.new(0)
    matches = @db[:matches]
    matches.each do |hash|
      hash.each do |a,b|
        if a == 'user'
          @ids[a]=b.to_s
        end
      end
    end
    @ids.each do|a,b|
      puts a.to_s + ":" + b.to_s
    end
  end




  def smartRoll(q)
    loadData
    @varb = q
    puts "Smart Roll: " + @varb.to_s
    @link_queue = Array.new(0)
    visit_queue = Array.new(0)
    puts "Gathering usernames..."

    # CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
    #   text = row[0]
    #   count = row[1].to_i
    #   visit_queue += [text] if (count == q)
    #   puts text if count == q
    #   puts count if count == q
    # end

    # importCSV(@username)
    @names.each do |a, b|
      if @names[a] == @varb
        visit_queue += [a]
        # puts a,b
      end
    end
    # puts visit_queue
    puts "Loading link queue..."
    # h = visit_queue.length
    c =0
    visit_queue.each do |user|
      @link_queue += ["http://www.okcupid.com/profile/#{user}/"]
      c += 1
    end
    j = 0
    has_matches = true
    quit = false
    while (has_matches == true && j<=31 && quit == false)
      if !(defined? @ignore[user])
        begin
          begin
          user = @link_queue[j].match(/profile\/(.*)\//)[1]
        rescue
          puts "Link queue error"
          # puts @link_queue
          # puts j
        end
          # match_per = link_queue[j].match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
          # @roll = @agent.get(link_queue[j])
          rollDice(@link_queue[j])
          clear
          smartRollGUI(user, q)
          tallyVisit(user, "")
          @names[user] = @names[user].to_i + 1
          j += 1
          sleep 10
        rescue SystemExit, Interrupt
          quit = true
          clear
          puts "","User quit. Saving data..."
          saveData(@names)
        rescue Exception => e
          # puts "There are no more matches that fit this criteria"
          puts e
          puts e.backtrace
          has_matches = false
        end
      end
    end
    saveData(@names)
  end


  def smartRollGUI(user, q)
    puts "=====================","    Smart Roll  (#{q})","=====================",""
    puts "User: " + user,"","","====================="
  end

  def stalk(user, times)
    puts "Stalk Mode","-------------","User: " + user.to_s

    i=1
    # until (i==times.to_i)
    5.times do
      roll = @agent.get("http://www.okcupid.com/profile/#{user}/")
      @names[user] += 1
      sleep 30000
    end
  end

  # puts "LazyCupid CLI 0.1"
  # puts "","","",""
  #print "Enter password:"
  #@password = gets.chomp
  #
  # @username = ARGV[0]
  # @password = ARGV[1]
  # @interval = ARGV[2]
  # @target =   ARGV[3]
  #


def rollDice(url="http://www.okcupid.com/getlucky?type=1")
  # begin
    @match = @agent.get(url)
    sleep 5
    @body = @match.parser.xpath("//body").to_html
    begin
      @user_name = @body.match(/\/profile\/(.*)\/photos/)[1]
      @match_per = @body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
    rescue
      begin
        @match_per = body.match(/<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
      rescue
        puts "Invalid user"
      end
    end
    tallyVisit(@user_name, @match_per)
  # rescue
    # puts "Invalid user"
  # end
end







  def run(mph)
    @mph = mph
    @max = 5000
    # @speed = s
    @speed = 3600/mph

    i=1
    match = @agent.get("http://www.okcupid.com/getlucky?type=1")
    sleep 5
    body = match.parser.xpath("//body").to_html
    loggedin = /logged_in/.match(body)
    if (loggedin)
    begin

        while (i<=5000) do
          match = @agent.get("http://www.okcupid.com/getlucky?type=1")
          sleep 5
          body = match.parser.xpath("//body").to_html
          # puts body
          begin


            user_name = body.match(/\/profile\/(.*)\/photos/)[1]
            match_per = body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
          rescue
            begin
              match_per = body.match(/<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
            rescue
              puts "Invalid user"
            end
          end
          tallyVisit(user_name, match_per)
          formatter(user_name, match_per, @names[user_name].to_s, @mph)
          i+=1
          # puts "********************************"
          sleep @speed

        end
        saveData(@names)
      rescue SystemExit, Interrupt
        clear
        puts "User quit. Saving data..."
        saveData(@names)
        puts "Done."
      rescue Exception => e
        puts e.message
        puts e.backtrace
    end
else
  puts "You are not logged in"
  puts body
end
  end

end
