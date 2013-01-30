require 'rubygems'

class Harvester
  attr_reader :type

  def leftbar_scrape
    array = body.scan(/href="\/profile\/([\w\d])\?leftbar\_match\=1"/)
    scrape_queue += array
  end

end
