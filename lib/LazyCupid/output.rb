module LazyCupid
  class Output
    attr_accessor :username, :match_name, :match_percent, :visit_count
    attr_reader :username, :match_name, :match_percent, :visit_count

    def initialize(args)
      @username = args[ :username]
      @smarty   = args[ :smart_roller]
      @db       = args[ :database]
      @distance_traveled = 0
      @total_visited = 0
      @total_visitors = 0
    end

    def clear_screen
      print "\e[2J\e[f"
    end

    def last_visited(match_name)
      return Match.where(:account => $login, :name => match_name).first[:last_visit]
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
        count: @db.get_visit_count(user[:handle]),
        last_online: last_online,
        last_visit: last_visited(user[:handle]),
        fog: user[:fog],
        kincaid: user[:kincaid]}
      puts result
    end

  end
end
