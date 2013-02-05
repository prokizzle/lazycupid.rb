require './DataManager'

class Lookup
  attr_reader :match, :data, :visits
  attr_accessor :match, :data, :visits

  def initialize(database, manual_import=false)
    @importer = database
    @importer.import if manual_import
    @match = @importer.data
    @visits = @importer.visit_count
  end

  def byUser(user)
    @match[user]
  end

  def visits(user)
    @visits[user]
  end

  def match
    @match
  end

  # def lastVisited(match_name)
  #   CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
  #     text = row[0]
  #     if text == match_name
  #       @date = row[2].to_s
  #     else
  #       @date = "N/a"
  #     end
  #   end

  #   puts @date
  # end

    def lastVisited(match_name)
        @do = @match.select {|k,v| k == match_name}
            @do.each do |k,v|
                puts v
            end
    end
end

  # if ARGV
  #   puts "Your username: "
  #   @account = gets.chomp
  #   search = Lookup.new(@account)
  #   puts "Their username: "
  #   @username = gets.chomp

  #   print "You have visited #{@username} " #if ARGV[0].to_s.match(/[A-z]+/)==true
  #   puts search.byUser(username).to_s + " times." #if ARGV[0].to_s.match(/[A-z]+/)==true
  # end
