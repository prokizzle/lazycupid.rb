require 'watir-webdriver'
require 'highline/import'
require 'watir-scroll'

module LazyCupid
  class FakeElement
    def exists?
      return false
    end

    def visible?
      return false
    end
  end

  class AutoRater
    attr_accessor :browser

    def initialize(args)
      @username = args[:username]
      @password = args[:password]
      @browser  = Watir::Browser.new $driver.to_sym
      @count    = 0
      @fake_element = FakeElement.new
    end

    # Ensure connection to webdriver re-opens on error
    def visit(url)
      begin
        @browser.goto url
      rescue Errno::ECONNREFUSED
        puts "Webdriver reconnecting..."
        @browser  = Watir::Browser.new $driver.to_sym
        login
        @browser.goto url
      end
    end

    def login
      print "AutoRater logging in with PhantomJS... " if $verbose
      @browser.goto("http://www.okcupid.com")

      @browser.link(:text => "Sign in").click
      sleep (1..3).to_a.sample.to_i
      @browser.text_field(:id => 'login_username').set(@username)
      sleep (1..3).to_a.sample.to_i
      @browser.text_field(:id => 'login_password').set(@password)
      sleep (1..3).to_a.sample.to_i
      @browser.button(:id => 'sign_in_button').click
      sleep (1..3).to_a.sample.to_i
      visit("http://www.okcupid.com/quickmatch")
      if $verbose
        puts logged in? ? "OK" : "failed"
      end
      return logged_in?
    end

    def logged_in?
      return @browser.h1(:id => 'home_heading').exists?
    end

    def rate(stars=5)
      # quickmatch_url = "https://www.okcupid.com/quickmatch"
      # @browser.goto(quickmatch_url) unless @browser.url == quickmatch_url
      # if @count > 6

      # @count = 0
      # end
      begin
        @browser.ul(:id => 'stars').li(:index => (stars-1)).a.click
      rescue  Exception => e
        if wrong_page(e)
          visit("http://www.okcupid.com/quickmatch")
        else
          puts "*********\n#{e.message}\n*********"
        end
      end
      # @count += 1
    end

    # error message types
    def wrong_page(e)
      e.message == 'unable to locate element, using {:id=>"stars", :tag_name=>"ul"}'
    end

    def delete_mutual_match_messages
      @browser.goto("http://www.okcupid.com/messages")
      sleep 4
      @browser.scroll.to :bottom

      4.times do
        @browser.send_keys [:command, '-']
      end
      @browser.scroll.to :center
      lines = @browser.spans :class => "previewline", :text => "It's a match!"
      if lines.to_a.size > 0
        puts "Cleaning up #{lines.to_a.size} messages..."
        lines.each {|m| m.click(:command) rescue sleep 0.2 }
        click_delete_button
      end
    end

    def click_delete_button
      sleep 2
      button = @browser.link(:id => 'message_delete_button')
      @browser.scroll.to [button.wd.location.x, button.wd.location.y]
      @browser.scroll.to :bottom
      Watir::Wait.until { @browser.div(:id => 'message_delete_panel').visible? }
      # @browser.div(:id => "message_delete_panel").link.click
      # @browser.execute_script('arguments[0].scrollIntoView();', @browser.div(:class => 'messages_bottom clearfix leftside'))
      # @browser.div(:id => 'message_delete_panel').click
      @browser.link(:id => 'message_delete_button').click
    end

    def delete_all_messages_on_page

    end

    def delete_replied_messages
      @browser.lis(:class => "repliedMessage").each{|r| r.click(:command)}
      click_delete_button
    end

    def delete_closed_account_messages
      @browser.images(:src => "http://ak1.okccdn.com/media/img/user/placeholder_60.png").each{|r| r.click(:command)}
      @browser.link(:id => 'message_delete_button').click
    end

    def delete_missed_instant_messages
      @browser.span(:text => /Missed Instant Message/).click(:command)
      click_delete_button
    end

    def cleanup_inbox
      @browser.goto("http://www.okcupid.com/messages")
      delete_missed_instant_messages
      delete_closed_account_messages
      delete_mutual_match_messages
    end

    def logout
      @browser.close
    end

  end
end
