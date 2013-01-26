require 'rubygems'

class Harvester
    :attr_reader type

    def leftbar_scrape
        array = body.scan(/href="\/profile\/[A-z0-9-_]\?leftbar_match=1"/)
        scrape_queue += array
    end

end
