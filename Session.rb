require 'rubygems'
require 'mechanize'

class Session
  attr_accessor :go_to, :agent
  attr_reader :go_to, :agent


  def initialize(username, password)
    @username = username
    @password = password
    @agent = Mechanize.new
  end

  def login
    begin
      # @agent.user_agent_alias = 'Mac Safari'
      page = @agent.get("http://www.okcupid.com/")
      form = page.forms.first
      form['username']=@username
      form['password']=@password
      page = form.submit
      sleep 1
    rescue Exception => e
      puts e.backtrace
      puts "Invalid password. Please try again"
    end
    is_logged_in
  end

  def logout
    unless is_logged out
      go_to("http://www.okcupid.com/logout")
    end
  end

  def is_logged_in
    go_to("http://www.okcupid.com/")
    /logged_in/.match(@body)
  end

  def is_logged_out
    go_to("http://www.okcupid.com/")
    /logged_out/.match(@body)
  end

  def go_to(url)
    @current_user = @agent.get(url)
    @body = @current_user.parser.xpath("//body").to_html
  end

  def logout
    go_to("http://www.okcupid.com/logout")
  end

  def session
    @agent
  end

  def body
    @body
  end


  def scrape_user_name
    begin
      @user_name = @body.match(/href="\/profile\/([A-z0-9_-]+)\/photos"/)[1]
    rescue
      @user_name = "N/A"
    end
  end

  def scrape_match_percentage
    begin
      @match_per = @body.match(/"match"\>\<strong>(\d+)\%\<\/strong\> Match\<\/p\>/)[1]
    rescue
      begin
        @match_per = @body.match(/<strong>(.+)\%\<\/strong\> Match\<\/p\>/)[1]
      rescue
        @match_per = "N/A"
      end
    end
  end

end
