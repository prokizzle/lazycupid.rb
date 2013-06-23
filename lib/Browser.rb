class Browser
  attr_reader :agent, :body, :current_user, :url, :hash, :page
  attr_accessor :agent, :body, :current_user, :url, :hash, :page


  def initialize(args)
    @username = args[ :username]
    @password = args[ :password]
    @agent = Mechanize.new
    @log      = args[ :log]
    @hash = Hash.new { |hash, key| hash[key] = 0 }
    # @response = Hash.new { url: nil, body: nil, html: nil, hash: nil }
  end

  def login
    begin
      @agent.user_agent_alias = ['Mac Safari', 'Windows IE 7', 'Mac Firefox', 'Mac Mozilla', 'iPhone'].sample
      page = @agent.get("http://www.okcupid.com/")
      form = page.forms.first
      form['username']=@username
      form['password']=@password
      page = form.submit
      @page = page
      sleep 1
    rescue Exception => e
      puts e.backtrace
      puts "Invalid password. Please try again"
    end
    is_logged_in
  end

  def recaptcha?
    result = @page.parser.xpath("//body").to_html
    result.match(/recaptcha_only_if_image/)
  end

  def logout
    unless is_logged out
      go_to("http://www.okcupid.com/logout")
    end
  end

  def is_logged_in
    response = body_of("http://www.okcupid.com/", Time.now.to_i)
    /logged_in/.match(response[:body])
  end

  def is_logged_out
    response = body_of("http://www.okcupid.com/", Time.now.to_i)
    /logged_out/.match(response[:body])
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

  def body_of(link, request_id)
    @hash[request_id] = {ready: false}
    url = link
    @agent.read_timeout=30
    temp = @agent.get(url)
    @log.debug "#{@url}"
    returned_body = temp.parser.xpath("//body").to_html
    @hash[request_id] = {url: url.to_s, body: returned_body.to_s, html: temp, ready: true}
    {url: url.to_s, body: returned_body.to_s, html: temp, hash: request_id.to_i}
  end

  def request(link, request_id)
    @hash[request_id] = {ready: false}
    url = link
    @agent.read_timeout=30
    temp = @agent.get(url)
    @log.debug "#{@url}"
    returned_body = temp.parser.xpath("//body").to_html
    @hash[request_id] = {url: url.to_s, body: returned_body.to_s, html: temp, ready: true}
    {url: url.to_s, body: returned_body.to_s, html: temp, hash: request_id.to_i}
  end

  def html_of(link, request_id)
    url = link
    temp = @agent.get(url)
    @log.debug "#{@url}"
    {url: url, html: temp, hash: request_id}
  end

  def handle
    /\/profile\/(.+)/.match(@url)[1]
  end

  def logout
    go_to("http://www.okcupid.com/logout")
  end

  def account_deleted
    @body.match(/Uh\-oh/)
  end
end
