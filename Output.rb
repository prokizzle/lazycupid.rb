require 'rubygems'
require './lookup.rb'

class Output
  attr_accessor :username, :match_name, :match_percent, :visit_count
  attr_reader :username, :match_name, :match_percent, :visit_count

  def initialize(database, username)
    @username = username
    @search = database
  end

  def clear
    print "\e[2J\e[f"
  end

  def output(match_name, match_percent, speed, mode="normal")
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
    puts "  Visiting: #{match_name}"
    puts "  Match:    #{match_percent}%"
    puts "  Visits:   #{@search.byUser(match_name)}",""
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
