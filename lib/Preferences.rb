require './includes'

class Preferences
    def initialize(args)
        @browser = args[ :browser]
    end

    def raw
        @browser.current_user
    end

    def body
        @browser.body
    end

    def get_match_preferences
        @browser.go_to("http://www.okcupid.com/profile")
        gentation = raw.parser.xpath("//li[@id='ajax_gentation']").to_html
        ages = raw.parser.xpath("//li[@id='ajax_ages']").to_html
        location = raw.parser.xpath("//span[@id='ajax_location']")
        @looking_for = /(\w+) who like/.match(gentation)[1]
        @min_age = (/(\d{2}).+(\d{2})/).match(ages)[1]
        @max_age = (/(\d{2}).+(\d{2})/).match(ages)[2]
        @my_city = (/[\w\s]+,\s([\w\s]+)/).match(location)[1]
        # <li id="ajax_ages">Ages 20&ndash;35</li>
        puts @min_age, @max_age, @my_city, @looking_for
    end

end