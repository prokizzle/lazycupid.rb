# Override method for opposite of Nil
class Fixnum
  def swag?
    !self.nil? rescue false
  end
end

# Override method for opposite of Nil
class NilClass
  def swag?
    false
  end
end

module LazyCupid


  # Processes HTML requests and manages the current user session for OKCupid
  #
  # @param username [Symbol] [username to login with]
  # @param password [Symbol] [password to login with]
  # @param log      [Symbol] [the path to folder containing log files]
  class Browser
    attr_accessor :agent, :body, :current_user, :url, :hash, :page, :page_source, :login_status


    def initialize(args)
      @username = args[ :username]
      @password = args[ :password]
      @agent = Mechanize.new
      @log      = args[ :log]
      @hash = Hash.new { |hash, key| hash[key] = 0 }
      delete_keys = lambda {|k| k.delete(key)}
      retrieved_responses = lambda {|h,k| k[:retrieved] == true}
      # @response = Hash.new { url: nil, body: nil, html: nil, hash: nil }
    end

    # Logs in to OKCupid and initializes a Mechanize agent
    #
    # @return [Boolean] True if account has been logged in successfully
    #
    def login
      # Mechanize settings
      agent.keep_alive               = false
      agent.idle_timeout             = 5
      agent.read_timeout             = 5
      agent.user_agent_alias         = ['Mac Safari', 'Mac Firefox'].sample
      agent.agent.http.debug_output  = $stderr if $debug

      # OKCupid login sequence
      @page                           = agent.get("http://www.okcupid.com/")
      form                            = page.forms[1]
      form['username']                = @username
      form['password']                = @password
      @page                           = form.submit
      sleep 1

      # Check if logged in
      @page_source                    = @page.parser.xpath("//html").to_html.to_s
      @login_status                   = check_session_status
      is_logged_in?
    end

    # Determines if captcha is required to login
    #
    # @return [Boolean] True if captcha has been detected on login page
    #
    def recaptcha?
      (page_source =~ /recaptcha_only_if_image/).swag?
    end

    # Logs out / ends OKCupid login session
    def logout
      unless is_logged out
        go_to("http://www.okcupid.com/logout")
      end
    end

    # Determines if account has logged in successfully
    #
    # @return [Boolean] True if account has been logged in
    #
    def is_logged_in?
      (page_source =~ /loggedin/).swag? rescue nil
    end

    # Determines status of OKCupid session
    # Useful for login interaction screen
    #
    # @return String status of login attempt
    def check_session_status
      # @page         = agent.get("http://www.okcupid.com/")
      # @page_source  = @page.parser.xpath("//html").to_html.to_s

      if is_logged_in?
        "Logged in"
      elsif wrong_password?
        "Incorrect username or password"
      elsif is_deleted?
        "Account has been deleted"
      elsif is_deactivated?
        "Account has been deactivated"
      elsif recaptcha?
        "Recaptcha has been detected. Login via browser first"
      else
        "Unknown login error"
      end
    end

    def is_deactivated?
      (page_source =~ /\bRestore your account\b/).swag?
    end

    def wrong_password?
      # p page_source
      (page_source =~ /\byour info was incorrect\b/).swag?
    end

    # Determines if OKCupid login session has been ended
    #
    # @return [Boolean] True is account has been logged out
    #
    def is_logged_out?
      (page_source =~ /logged_out/).swag?
    end

    # Determines if logged in account has been deleted by moderators    #
    #
    # @return [Boolean] [True if account has been deleted]
    #
    def is_deleted?
      (page_source =~ /\baccount was deleted\b/).swag?
    end


    # Removes a html response hash from the hash of responses
    #
    # @param key [Integer] original timestamp used to request a page
    # @return [Boolean] True if response has been deleted
    #
    def delete_response(key)
      @hash.tap {|k| k.delete(key)}
    end

    def remove_retrieved_responses
      responses = @hash.select &retrieved_responses
      responses.map {@hash.tap &delete_keys}
    end


    # Visits URL and returns HTML body
    #
    # @param link [String] [URL of html page to return]
    # @return [String] [HTML value of body element]
    #
    def go_to(link)
      @url = link
      # begin
      @current_user = agent.get(link)
      # @log.debug "#{@url}"
      @body = @current_user.parser.xpath("//body").to_html
      # rescue
      # end
    end

    def body_of(link, request_id)
      @hash[request_id]       = {ready: false}
      url                     = URI.escape(link)
      # agent.read_timeout=30
      page_object = agent.get(url)
      # @log.debug "#{@url}"
      page_object.encoding = 'utf-8'
      page_body = page_object.parser.xpath("//html").to_html
      @hash[request_id] = {url: url.to_s, body: page_body.to_s, html: page_object, ready: true}
      {url: url.to_s, body: page_body.to_s, html: page_object, hash: request_id.to_i}
    end

    # Initiates a http request via Mechanize agent
    #
    # @param link       [String] [URL of page to get]
    # @param request_id [Integer] [timestamp to identify and retrieve returned data]
    # @return [Boolean]
    #
    def send_request(link, request_id)
      # request_id          = Time.now.to_i
      @hash[request_id]     = {ready: false}
      url                   = URI.escape(link)
      agent.read_timeout    = 30
      page_object           = agent.get(link)
      page_object.encoding  = 'utf-8'
      page_body             = page_object.parser.xpath("//body").to_html
      page_source           = page_object.parser.xpath("//html").to_html
      @hash[request_id]     = {url: url.to_s, body: page_body.to_s, html: page_object, ready: true, source: page_source, retrieved: false}
      true
    end

    # Retrieves a hash of attributes parsed from a page
    #
    # @param request_id [Integer] timestamp value originally passed to send_request method
    # @return [Hash] A hash containing strings and objects with the requested page data
    #   url: a String representing the original URL passed to the getter
    #   body: A string HTML source of the content between the page's body tags
    #   html: An unaltered Mechanize page object
    #   ready: Boolean value indicating whether or not Mechanize has finished loading
    #           the page into memory
    #
    def get_request(request_id)
      return @hash[request_id]
    end

    # Initiates a http request via Mechanize agent
    #
    # @param link       [String] [URL of page to get]
    # @param request_id [Integer] [timestamp to identify and retrieve returned data]
    # @return [Boolean]
    #
    def request(link, request_id)
      @hash[request_id] = {ready: false}
      url = URI.escape(link)
      agent.read_timeout=30
      page_object = agent.get(link)
      page_object.encoding = 'utf-8'
      # @log.debug "#{@url}"
      page_body = page_object.parser.xpath("//body").to_html
      @hash[request_id] = {url: url.to_s, body: page_body.to_s, html: page_object, ready: true}
      {url: url.to_s, body: page_body.to_s, html: page_object, hash: request_id.to_i}
    end

    def html_of(link, request_id)
      url = URI.escape(link)
      page_object = agent.get(url)
      # @log.debug "#{@url}"
      {url: url, html: page_object, hash: request_id}
    end


    # Determines logged in username
    # @return [String] [logged in username]
    def handle
      /\/profile\/(.+)/.match(@url)[1]
    end

    # Logs out of OKcupid
    # @return [Boolean]
    def logout
      go_to("http://www.okcupid.com/logout")
    end

    def page_source
      @page.parser.xpath("//html").to_html.to_s
    end

    # Detects an invalid account or profile
    # @return [Boolean] [True if account is deleted]
    def account_deleted
      @body.match(/\bUh\-oh\b/)
    end
  end
end
