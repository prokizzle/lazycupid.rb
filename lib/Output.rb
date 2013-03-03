class Output
  attr_accessor :username, :match_name, :match_percent, :visit_count
  attr_reader :username, :match_name, :match_percent, :visit_count

  def initialize(args)
    @username = args[ :username]
    @you = args[ :stats]
    @distance_traveled = 0
  end

  def clear
    print "\e[2J\e[f"
  end

  def output(user, speed, mode="normal")
    case mode
    when "normal"
      mode_name = "AutoRoller"
    when "smart"
      mode_name = "SmartRoller"
    else
      mode_name = "Funyon Monkey"
    end

    clear
    puts "",""
    puts "LazyCupid Ruby","========================="
    puts "#{mode_name} @ #{speed} MPH","----------------------"
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

  def console_out(user)
    puts "#{@username}: #{user.handle}; #{user.match_percentage}%; #{user.state}; #{user.relative_distance}; #{@you.visited(user.handle)}"
  end

  def travel_plans(user)
    puts "*******************"
    @distance_traveled += (@last_destination.to_f - user.relative_distance.to_f).abs
    puts "#{@username} is visting #{user.state},","#{user.relative_distance} miles away."
    puts "Trip total: #{@distance_traveled}"
    @last_destination = user.relative_distance.to_f
  end

  def dashboard(visited, visitors)
    self.clear
    puts "LazyCupid Dashboard"
    puts "--------------------","",""
    puts "Updated:  #{Time.now}"
    puts "Account:  #{@username}"
    puts "Visited:  #{visited}"
    puts "Visitor:  #{visitors}"
  end


  def progress(total_matches)

  end

  def update_progress

  end

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
