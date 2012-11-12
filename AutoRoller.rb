require 'rubygems'
require 'mechanize'
require 'csv'
require 'sqlite3'
require 'set'
require_relative 'OutputScrape.rb'

class AutoVisitor

  attr_accessor :names
  attr_accessor :profile
  attr_accessor :username


def saveData(names)
  @storeCounts = OutputScrape.new
  @storeCounts.file = @username + "_count.csv"
  @storeCounts.clear
  @names.each do |a, b|
    row = [a, b]
    @storeCounts.data = row
    @storeCounts.append
  end
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
  @names = Hash.new {|h, k| h[k] = 0 }
  CSV.foreach(user.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|

  text = row[0]
  @names[text] += 1
  # puts puts text + ": " + names[text].to_s
end
end

def login(user, pass)
  @username = user
  @password = pass

end



def setProfile
  if ARGV[0]
    profile=ARGV[0]
  else
    profile="bb86"
  end
  if ARGV[1]
    @max = ARGV[1].to_i
  else
    @max = 5
  end
  if ARGV[3]
    @speed = ARGV[3].to_i
  else
    @speed = 10
  end
  if ARGV[5]
    @visible = false
  else
    @visible = true
  end

  if (profile == "ying")
    login('danceyrselfcln','123457')
    @username = 'danceyrselfcln'
    @password = '123457'
  elsif (profile == 'bsw') then 

    @username = '***REMOVED***'
    @password = 'Pr0k1zzl3'
    login(@username,@password)
  elsif profile=='bb86' then
    @username = 'bostonboy86'
    @password = 'eGrwpkqn9MpJjVjYpY2zELuwMCGq'
    login(@username,@password)
  elsif profile == 'james'
    @username = 'bunellcakess'
    @password = '***REMOVED***'
    login(@username,@password)
  end
end
# profile = 'bb86'
puts "LazyCupid CLI 0.1"
# puts "","","",""
#print "Enter password:"
#@password = gets.chomp
#
# @username = ARGV[0]
# @password = ARGV[1]
# @interval = ARGV[2]
# @target =   ARGV[3]
#










def run(m, s)
  @max = m
  @speed = s


  @saveResults = OutputScrape.new
  @saveResults.file = username.to_s + ".csv"
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
  i=1

  puts "---------"
  # puts "","","",""
  puts "Hitting " + @max.to_s + " matches total,"
  puts "one every " + @speed.to_s + " seconds."
  while (i<=@max.to_i) do
    # puts page.parser.xpath("//body")
    match = @agent.get("http://www.okcupid.com/getlucky?type=1")
    body = match.parser.xpath("//body").to_html
    # puts body
    # puts match.parser.xpath("//body")
    begin
      user_name = body.match(/\/profile\/(.*)\/photos/)[1]
      @names[user_name] += 1
      match_per = body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
      @log[user_name] = (@log[user_name].to_i + 1).to_s
      puts "********************************"
      puts "Just visited " + user_name.to_s
      puts "You are a " + match_per + " percent match"
      puts "You have visited her " + @names[user_name].to_s + " times."
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end 
    row = [user_name.to_s,match_per.to_s, Time.now, Time.now.to_i]
    @saveResults.data = row
    @saveResults.append
    i+=1
    sleep @speed
  end
end
end
  
  lazyCupid = AutoVisitor.new

  @u = ARGV[0]
  @p = ARGV[1]
  @m = ARGV[2].to_i
  @s = ARGV[3].to_i

  lazyCupid.login(@u,@p)
  lazyCupid.loadData
  lazyCupid.run(@m, @s)
  lazyCupid.saveData(@names)
  
  # singleVisits
  puts ""
  puts "Done."
  puts "---"

