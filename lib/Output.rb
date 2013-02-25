class Output
  attr_accessor :username, :match_name, :match_percent, :visit_count
  attr_reader :username, :match_name, :match_percent, :visit_count

  def initialize(args)
    @username = args[ :username]
    @search = args[ :stats]
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
    puts "  Visits:      #{@search.byUser(user.handle)}"
    puts "  Visited You: #{@search.visits(user.handle)}",""
    puts "to quit press ctrl-c"
  end

  def progress(total_matches)

  end

  def update_progress

  end


  # def p(i)
  #   puts i
  # end

  # def print(i)
  #   print i
  # end

end
