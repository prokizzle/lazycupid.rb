module LazyCupid
  class RegEx

    def self.parsed_location(string)
      result    = string.scan(/,/)
      if result.size == 2
        city    = string.match(/(.+), (.+), (.+)/)[1]
        state   = string.match(/(.+), (.+), (.+)/)[2]
        country = string.match(/(.+), (.+), (.+)/)[3]
      elsif result.size == 1
        city    = string.match(/(.+), (.+)/)[1]
        state   = string.match(/(.+), (.+)/)[2]
        country = "United States"
      end
      {city: city, state: state, country: country }
    end

    def friend_percentage_regex
      "/>(\d+). Friend.*/"
    end

  end
end
