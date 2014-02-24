module LazyCupid
  class Output
    attr_accessor :username, :match_name, :match_percent, :visit_count
    attr_reader :username, :match_name, :match_percent, :visit_count

    def initialize(args)
      @username = args[ :username]
      @you      = args[ :stats]
      @smarty   = args[ :smart_roller]
      @distance_traveled = 0
      @total_visited = 0
      @total_visitors = 0
    end

    def clear_screen
      print "\e[2J\e[f"
    end

    def log(user)
      print @username
      last_online = Time.at(user[:last_online]||0).ago.to_words
      last_online = "Online now" if last_online == "47 years ago"
      result = {user: user[:handle],
        gender: user[:gender],
        age: user[:age],
        distance: user[:distance],
        match_percent: user[:match_percentage],
        enemy: user[:enemy_percentage],
        friend: user[:friend_percentage],
        city: user[:city],
        state: user[:state],
        sexuality: user[:sexuality],
        count: @you.visited(user[:handle]),
        last_online: last_online,
        last_visit: @you.last_visited(user[:handle]),
        fog: user[:fog],
        kincaid: user[:kincaid]}
      puts result
    end

  end
end
