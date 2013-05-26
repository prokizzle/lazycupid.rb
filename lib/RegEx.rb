class RegEx

  def location_array(location)
    result    = location.scan(/,/)
    if result.size == 2
      city    = location.match(/(.+), (.+), (.+)/)[1]
      state   = location.match(/(.+), (.+), (.+)/)[2]
      country = location.match(/(.+), (.+), (.+)/)[3]
    elsif result.size == 1
      city    = location.match(/(.+), (.+)/)[1]
      state   = location.match(/(.+), (.+)/)[2]
      country = "United States"
    end
    {city: city, state: state, country: country }
  end

end