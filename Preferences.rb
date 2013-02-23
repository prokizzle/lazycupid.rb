require './includes'

class Preferences
    def initialize(args)
        @browser = args[ :browser]
    end

    def raw
        @browser.current_user
    end

    def get_match_preferences
        @browser.go_to("http://www.okcupid.com/profile/")
        gentation = raw.parser.xpath("//*[@id='ajax_gentation']").to_html
        looking_for = /(\w+)\s/.match(gentation)[1]
        puts looking_for
    end

end