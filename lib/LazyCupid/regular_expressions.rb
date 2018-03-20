module LazyCupid
  class RegEx

    def self.parsed_location(string)
      result    = string.scan(/,/)
      if result.size == 2
        city    = string.match(/(.+), (.+), (.+)/)[1]
        state   = string.match(/(.+), (.+), (.+)/)[2]
        country = string.match(/(.+), (.+), (.+)/)[3]
      elsif result.size == 1
        begin
          city    = string.match(/(.+), (.+)/)[1]
          state   = string.match(/(.+), (.+)/)[2]
          country = "United States"
        rescue
          puts "* Location Parser Error! *"
          puts string
        end
      end
      {city: city, state: state, country: country }
    end


  end
end
