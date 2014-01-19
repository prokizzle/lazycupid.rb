require 'watir-webdriver'
require 'highline/import'

module LazyCupid
  class AutoRater
    def initialize(*args)
      @username = args[:username]
      @password = args[:password]
      @browser  = Watir::Browser.new :phantomjs

    def login
      puts "AutoRater logging in with PhantomJS" if $verbose
      @browser.goto("http://www.okcupid.com")

      @browser.link(:text => "Sign in").click
      sleep 2
      @browser.text_field(:id => 'login_username').set(@username)
      sleep 2
      @browser.text_field(:id => 'login_password').set(@password)
      sleep 2
      @browser.button(:id => 'sign_in_button').click
      sleep 2
      @browser.goto("http://www.okcupid.com/quickmatch")
      sleep 1
    end

    def rate(stars=4)
      @browser.ul(:id => 'stars').li(:index => (stars-1)).click
    end

  end
end
