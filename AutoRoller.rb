require 'rubygems'
require 'mechanize'
require 'csv'
# require 'sqlite3'
# require 'set'
require_relative 'OutputScrape.rb'

class AutoVisitor

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
    puts "    LazyCupid Ruby","========================="
    puts "    AutoRoller @ #{d} MPH","----------------------"
    puts "    For: #{@username}",""
    puts "     Visiting: #{a}"
    puts "     Match:    #{b}%"
    puts "     Visits:   #{c}"
  end


  def saveData(names)
    print "Saving..."
    @storeCounts = OutputScrape.new
    @storeCounts.file = @username + "_count.csv"
    @storeCounts.clear
    @names.each do |a, b|
      row = [a, b]
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

  def loadData

    @names = Hash.new {|h, k| h[k] = 0 }
    begin
      #load count file data
      CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        count = row[1].to_i
        @names[text] = count
      end
    rescue
      #if count file not found, build one from log files
      CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
        text = row[0]
        @names[text] += 1
        # puts puts text + ": " + names[text].to_s
      end
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
        @names[text] = (@names[text].to_i + 1).to_s

      end
      # puts puts text + ": " + names[text].to_s
    end
    print " Done.\n"
    saveData(@names)
  end

  def tallyVisit(name)
    @names[name] = (@names[name].to_i + 1).to_s
  end

  def login(user, pass)
    begin
      @username = user
      @password = pass
      @saveResults = OutputScrape.new
      @saveResults.file = @username + ".csv"
      @log = Hash.new
      @agent = Mechanize.new
      page = @agent.get("http://www.okcupid.com/login")
      # link = page.link_with(:text=>"CUSTOMER LOGIN")
      # page = link.click
      form = page.forms.first
      form['username']=@username
      form['password']=@password
      page = form.submit
      puts "Logged in as: " + username.to_s
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




  def smartRoll(number)

    puts "Smart Roll: " + number.to_s
    link_queue = Array.new(0)
    visit_queue = Array.new(0)
    puts "Gathering usernames..."
    CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
      text = row[0]
      count = row[1].to_i
      if count == number
        visit_queue += [text]
      end
    end

    puts "Loading link queue..."
    # h = visit_queue.length
    c =0
    visit_queue.each do |user|

      # puts "Visting: " + user
      # roll = @agent.get("http://www.okcupid.com/profile/#{user}/")
      if !(checkIgnore? user)
        link_queue += ["http://www.okcupid.com/profile/#{user}/"]
      end
      c += 1
      # @names[user] += 1
      # sleep 10
      # h = h- 1
      # puts h
      # if ((((visit_queue.length - h)/visit_queue.length)%2)==0)
      #   print "."
      # end
    end
    puts c
    j = 0
    has_matches = true
    quit = false
    while (has_matches == true && j<=31 && quit == false)

      if !(defined? @ignore[user])
        begin
          user = link_queue[j].match(/profile\/(.*)\//)[1]
          roll = @agent.get(link_queue[j])
          clear
          smartRollGUI(user)
          tallyVisit(user)
          j += 1
          sleep 10
        rescue SystemExit, Interrupt
          quit = true
          clear
          puts "","User quit. Saving data..."
        rescue
          puts "There are no more matches that fit this criteria"
          has_matches = false
        end
      end

    end

    saveData(@names)
  end


  def smartRollGUI(user)
    puts "=====================","    Smart Roll","=====================",""
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










  def run(mph)
    @mph = mph
    @max = 5000
    # @speed = s
    @speed = 3600/mph

    i=1


    begin
      puts "---------"
      # puts "","","",""
      puts "Hitting " + @max.to_s + " matches total,"
      puts "one every " + @speed.to_s + " seconds."
      while (i<=@max.to_i) do
          begin
            match = @agent.get("http://www.okcupid.com/getlucky?type=1")
            body = match.parser.xpath("//body").to_html

            user_name = body.match(/\/profile\/(.*)\/photos/)[1]
            tallyVisit(user_name)
            match_per = body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
            @log[user_name] = (@log[user_name].to_i + 1).to_s
          rescue
            puts "Invalid user"
          end
          clear
          # puts "Just visited " + user_name.to_s
          # puts "You are a " + match_per + " percent match"
          # puts "You have visited her " + @names[user_name].to_s + " times."
          formatter(user_name, match_per, @names[user_name].to_s, @mph)

          row = [user_name.to_s,match_per.to_s, Time.now, Time.now.to_i]
          @saveResults.data = row
          @saveResults.append
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

    end
  end
