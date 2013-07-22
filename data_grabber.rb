require_relative 'lib/LazyCupid/browser'
require 'mechanize'



class App
  attr_reader :messages

  def initialize(browser)
    @browser = browser
    @messages = Array.new
  end

  def inbox_page_scraper(inbox_body, inbox_page)
    message_list = inbox_body.scan(/id\="message_(\d+)"/)
    message_list.each do |id|
      thread = inbox_page.parser.xpath("//li[@id='message_#{id[0]}']")
      info = thread.to_html.match(/([-\w\d_]+)\?cf=messages..class="photo">.+src="(.+)" border.+threadid.(\d+).+fancydate_\d+.. (\d+),/)
      @messages.push({handle: info[1], photo_thumbnail: info[2], thread_id: info[3], thread_url: "http://www.okcupid.com/messages?readmsg=true&threadid=#{info[3]}&folder=1", message_date: info[4]})
    end
  end

  def analyze_message_thread(thread)
    request = @browser.request(thread[:thread_url], Time.now.to_i)
    # thread_html = request[:html]
    thread_page = request[:body]
    replies = thread_page.scan(/Report this/)
    thread[:replies] = replies.size
    # puts "#{thread[:handle]} #{replies.size} replies"
    # puts "#{thread[:handle]} #{thread[:message_date]}"
    puts thread
  end

end

browser = LazyCupid::Browser.new(username: "***REMOVED***", password: "***REMOVED***")
browser.login
time_key = Time.now.to_i
response = browser.request("http://www.okcupid.com/visitors", time_key)
vistors_body = response[:body]
vistors_page = response[:html]
response = browser.request("http://www.okcupid.com/messages", time_key)
inbox_body = response[:body]
inbox_page = response[:html]
@messages = Array.new

# File.open("visitors.html", "w") do |f|
#   f.write(vistors_page)
# end

# File.open("messages.html", "w") do |f|
#   f.write(inbox)
# end
#

app = App.new(browser)
app.inbox_page_scraper(inbox_body, inbox_page)
app.messages.each do |thread|
  app.analyze_message_thread(thread)
end


# thread_page.scan(/"message_body">.+<.em>(.+)<em/).each {|r| puts r}
