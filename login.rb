require 'rubygems'
require 'mechanize'
require 'csv'
require 'sqlite3'
require 'set'






  def compileStats(s, names)
    jew = names.sort_by {|a, b| b.to_i }
    @storeCounts = OutputScrape.new
    @storeCounts.file = @username + "_count.csv"
    @storeCounts.clear
    s.each do |a| 
      row = [a, a.size]
      @storeCounts.data = row
      @storeCounts.append
    end
  end

class OutputScrape

  attr_accessor :file
  attr_accessor :data

  def initialize(file="output.csv")
    @data = Array.new
    @file = file
  end

  def append
    CSV.open(@file, 'ab') do |csv|
      csv << @data
    end
  end

  def clear
    empty = Array.new(0)
    CSV.open(@file, 'wb') do |csv|
      csv << empty
    end
  end

  def dbwrite(username)

  end






end
if ARGV[0]
  profile=ARGV[0]
else
  profile="bb86"
end
if ARGV[1]
  max = ARGV[1].to_i
else
  max = 5
end
if ARGV[3]
  speed = ARGV[3].to_i
else
  speed = 10
end
if ARGV[5]
  visible = false
else
  visible = true
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
if (profile == "ying")
  @username = 'danceyrselfcln'
  @password = '123457'
elsif (profile == 'bsw') then
  @username = '***REMOVED***'
  @password = 'Pr0k1zzl3'
elsif profile=='bb86' then
  @username = 'bostonboy86'
  @password = 'eGrwpkqn9MpJjVjYpY2zELuwMCGq'
elsif profile == 'james'
  @username = 'bunellcakess'
  @password = '***REMOVED***'
end


names = Hash.new {|h, k| h[k] = 0 }
freqs = Hash.new(0)
s = SortedSet.new
n = Set.new
CSV.foreach(@username + ".csv", :headers => true, :skip_blanks => false) do |row|

       text = row[0]
       names[text] += 1
       puts puts text + ": " + names[text].to_s

end


# CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
#   text = row[0]
#   count = row[1].to_i
#   if count == 10
#     n.add(text)
#   end
# end


@saveResults = OutputScrape.new
@saveResults.file = @username.to_s + ".csv"
log = Hash.new
agent = Mechanize.new
page = agent.get("http://www.okcupid.com/login")
# link = page.link_with(:text=>"CUSTOMER LOGIN")
# page = link.click
form = page.forms.first
form['username']=@username
form['password']=@password
page = form.submit
puts "Logged in as: " + @username.to_s

i=0

puts "---------"
# puts "","","",""
puts "Hitting " + max.to_s + " matches total,"
puts "one every " + speed.to_s + " seconds."
until (i==max) do
    # puts page.parser.xpath("//body")
    match = agent.get("http://www.okcupid.com/getlucky?type=1")
    body = match.parser.xpath("//body").to_html
    # puts body
    # puts match.parser.xpath("//body")
    begin
      user_name = body.match(/\/profile\/(.*)\/photos/)[1]
      names[user_name] += 1
      match_per = body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
      log[user_name] = (log[user_name].to_i + 1).to_s
      puts "********************************"
      puts "Just visited " + user_name.to_s
      puts "You are a " + match_per + " percent match"
      puts "You have visited her " + names[user_name] + " times."
    rescue Exception => e 
      puts e.message
    end

    # print "." if (i%5==0)
    # if (2 == true)

    # else
    #   print "."
    # end
    row = [user_name.to_s,match_per.to_s, Time.now, Time.now.to_i]
    @saveResults.data = row
    @saveResults.append
    # @db.execute "INSERT INTO ying (Name) VALUES ('#{user_name}')"

    i+=1
    sleep speed.to_i
  end
  compileStats(s, names)
  puts ""
  puts "Done."
  puts "---"
# puts names
  # nebb = s.sort_by {|a, b| a.size }
  # puts nebb
  # puts names
  # names.each do |a,b|
  #  puts "a: " + a
  #  puts "b: " + b
  # end


