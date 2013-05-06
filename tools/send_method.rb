# class Events

  def msg_notify
    puts "New message"
  end

  def stalk
    puts "New Visit"
  end

# end

# @events = Events.new
temp = "stalk"
self.send(temp)