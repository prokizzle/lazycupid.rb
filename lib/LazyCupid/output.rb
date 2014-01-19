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

    def output(user, roll_type)


      clear_screen
      puts "",""
      puts "LazyCupid Ruby","========================="
      puts "  For: #{@username}",""
      puts "  Visiting:    #{user.handle}"
      puts "  Match:       #{user.match_percentage}%"
      puts "  Gender:      #{user.gender}"
      puts "  Sexuality:   #{user.sexuality}"
      puts "  State:       #{user.state}"
      puts "  Distance:    #{user.relative_distance}"
      puts "  Visits:      #{@you.visited(user.handle)}"
      puts "  Last visit:  #{@you.last_visited(user.handle)}"
      puts "  Visited You: #{@you.were_visited(user.handle)}",""
      puts "to quit press ctrl-c"
    end

    def log(user)
      print @username
      last_online = Time.at(user[:last_online]||0).ago.to_words
      last_online = "Online now" if last_online == "47 years ago"
      result = {user: user[:handle], gender: user[:gender], age: user[:age], distance: user[:distance], match_percent: user[:match_percentage], enemy: user[:enemy_percentage], friend: user[:friend_percentage], city: user[:city], state: user[:state], sexuality: user[:sexuality], count: @you.visited(user[:handle]), last_online: last_online, fog: user[:fog], kincaid: user[:kincaid]}
      puts result
    end

    def travel_plans(user)
      puts "*******************"
      @distance_traveled += (@last_destination.to_f - user.relative_distance.to_f).abs
      puts "#{@username} is visting #{user.state},","#{user.relative_distance} miles away."
      puts "Trip total: #{@distance_traveled}"
      @last_destination = user.relative_distance.to_f
    end

    def dashboard(visited, visitors, start_time, progress_amount, current_state)

      # messages = args[ :messages]
      clear_screen
      puts "LazyCupid Dashboard"
      puts "--------------------","",""
      puts "Started:   #{Time.at(start_time).ago.to_words}"
      puts "Updated:   #{Time.now.hour}:#{Time.now.min}"
      puts "Account:   #{@username}"
      puts "Visited:   #{visited}"
      puts "Visitors:  #{visitors}"
      puts "State:     #{current_state}.",""

      @bar.increment! progress_amount

    end


    def progress(total_matches)
      @bar = ProgressBar.new(total_matches, :counter, :eta)
    end

    # def update_progress(amount)
    #   @progress_amount = amount
    # end

    # def users_visited
    #   @smarty.stats(:item => "visited")
    # end

    # def visitors_tally
    #   @smarty.stats(:item => "visitors")
    # end

    # def roll_start_time
    #   @smarty.stats(:item => "start_time")
    # end

    def state_abbr(state)
      @state_abbr[state]
    end

    @state_abbr = {
      'Alabama' =>'AL',
      'Alaska' =>'AK',
      'America Samoa' =>'AS',
      'Arizona' =>'AZ',
      'Arkansas' =>'AR',
      'California' =>'CA',
      'Colorado' =>'CO',
      'Connecticut' =>'CT',
      'Delaware' =>'DE',
      'District of Columbia' =>'DC',
      'Micronesia1' =>'FM',
      'Florida' =>'FL',
      'Georgia' =>'GA',
      'Guam' =>'GU',
      'Hawaii' =>'HI',
      'Idaho' =>'ID',
      'Illinois' =>'IL',
      'Indiana' =>'IN',
      'Iowa' =>'IA',
      'Kansas' =>'KS',
      'Kentucky' =>'KY',
      'Louisiana' =>'LA',
      'Maine' =>'ME',
      'Islands1' =>'MH',
      'Maryland' =>'MD',
      'Massachusetts' =>'MA',
      'Michigan' =>'MI',
      'Minnesota' =>'MN',
      'Mississippi' =>'MS',
      'Missouri' =>'MO',
      'Montana' =>'MT',
      'Nebraska' =>'NE',
      'Nevada' =>'NV',
      'New Hampshire' =>'NH',
      'New Jersey' =>'NJ',
      'New Mexico' =>'NM',
      'New York' =>'NY',
      'North Carolina' =>'NC',
      'North Dakota' =>'ND',
      'Ohio' =>'OH',
      'Oklahoma' =>'OK',
      'Oregon' =>'OR',
      'Palau' =>'PW',
      'Pennsylvania' =>'PA',
      'Puerto Rico' =>'PR',
      'Rhode Island' =>'RI',
      'South Carolina' =>'SC',
      'South Dakota' =>'SD',
      'Tennessee' =>'TN',
      'Texas' =>'TX',
      'Utah' =>'UT',
      'Vermont' =>'VT',
      'Virgin Island' =>'VI',
      'Virginia' =>'VA',
      'Washington' =>'WA',
      'West Virginia' =>'WV',
      'Wisconsin' =>'WI',
      'Wyoming' =>'WY'
    }


    # def p(i)
    #   puts i
    # end

    # def print(i)
    #   print i
    # end

  end
end
