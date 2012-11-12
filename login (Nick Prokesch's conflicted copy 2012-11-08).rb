require 'rubygems'
require 'mechanize'
require 'csv'

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

  end # method append

end


#print "Enter password:"
#@password = gets.chomp
@password = 'Pr0k1zzl3'
@username = '***REMOVED***'
@saveResults = OutputScrape.new
@saveResults.file = @username + ".csv"
log = Hash.new
agent = Mechanize.new
page = agent.get("http://www.okcupid.com/login")
# link = page.link_with(:text=>"CUSTOMER LOGIN")
# page = link.click
form = page.forms.first
form['username']='***REMOVED***'
form['password']=@password
page = form.submit


i=0
until (i==200) do
    # puts page.parser.xpath("//body")
    match = agent.get("http://www.okcupid.com/getlucky?type=1")
    body = match.parser.xpath("//body").to_html
    # puts body
    # puts match.parser.xpath("//body")
  begin
    user_name = body.match(/\/profile\/(.*)\/photos/)[1]
    match_per = body.match(/"match"\>\<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
  rescue
    puts "an error occurred"
  end
    puts ""

    puts "Username: " + user_name.to_s
    puts "Match:    " + match_per + "%"
    row = [user_name.to_s,match_per.to_s, Time.now, Time.now.to_i]
    @saveResults.data = row
    @saveResults.append
    log[user_name] = (log[user_name].to_i + 1).to_s
    puts "Visits:   " + log[user_name]
    i+=1
    sleep 5
  end

log.each_pair do |x, y|
  puts x
  puts y
end