module LazyCupid
  class Preferences
    def initialize(args)
      @browser = args[ :browser]
    end

    def match_preferences
      r = @browser.body_of("http://www.okcupid.com/profile", Time.now.to_i)
      gentation = r[:html].parser.xpath("//li[@id='ajax_gentation']").to_html
      ages = r[:html].parser.xpath("//li[@id='ajax_ages']").to_html
      location = r[:html].parser.xpath("//span[@id='ajax_location']")
      @looking_for = /(\w+) who like/.match(gentation)[1]
      @min_age = (/(\d{2}).+(\d{2})/).match(ages)[1]
      @max_age = (/(\d{2}).+(\d{2})/).match(ages)[2]
      @my_city = (/[\w\s]+,\s([\w\s]+)/).match(location)[1]
      # <li id="ajax_ages">Ages 20&ndash;35</li>
      {min_age: @min_age, max_age: @max_age, city: @my_city, looking_for: @looking_for}
    end
  end
end
