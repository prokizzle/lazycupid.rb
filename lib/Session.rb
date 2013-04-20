class Session
  attr_accessor :go_to, :agent, :body, :body2, :current_user, :current_user2, :handle, :url, :api_body, :api_current_user, :harv_body, :harv_current_user
  attr_reader :go_to, :agent, :body, :body2, :current_user, :current_user2, :handle, :url, :api_body, :api_current_user, :harv_body, :harv_current_user


  def initialize(args)
    @username = args[ :username]
    @password = args[ :password]
    @agent = Mechanize.new
    @log      = args[ :log]
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

  def go_to(link)
    @url = link
    # begin
    @current_user = @agent.get(link)
    @log.debug "#{@url}"
    @body = @current_user.parser.xpath("//body").to_html
    # rescue
    # end
  end

  def get_body_of(link)
    url = link
    temp = @agent.get(url)
    @log.debug "#{@url}"
    body = temp.parser.xpath("//body").to_html
    {url: url, body: body}
  end

  def get_html_of(link)
    url = link
    temp = @agent.get(url)
    @log.debug "#{@url}"
    {url: url, html: temp}
  end

  def handle
    /\/profile\/(.+)/.match(@url)[1]
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

  def body2
    @body2
  end

  def account_deleted
    @body.match(/Uh\-oh/)
  end
end
