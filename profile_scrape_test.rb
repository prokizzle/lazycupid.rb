require "./includes"

class ProfileScrapeTest

  def initialize(args)
    @browser = args[ :browser]
    # @user    = args[ :user]
  end

  def body
    @browser.body
  end

  def raw
    @browser.current_user
  end

  def selector_handle
    @browser.current_user.parser.xpath("//span[@id='basic_info_sn']").text
  end

  def regex_handle
    /username.>(.+)<.p>.<p.class..info.>/.match(body)[1] if body.match(/username.>(.+)<.p>.<p.class..info.>/)
  end

  def load_profile(username)
    @browser.go_to("http://www.okcupid.com/profile/#{username}")
  end

  def login
    @browser.login
  end

  def logout
    @browser.logout
  end

  def url
    @browser.url
  end

  def intended_username
    /\/profile\/(.+)/.match(@browser.url)[1]
  end

end

browser = Session.new(:username => "danceyrselfcln", :password => "123457")
app = ProfileScrapeTest.new(:browser => browser)
app.login
app.load_profile("***REMOVED***")
puts app.regex_handle.to_s
puts app.selector_handle.to_s
puts app.url
puts app.intended_username.to_s
app.logout
