
class Lookup
  attr_reader :match, :data, :visits
  attr_accessor :match, :data, :visits

  def initialize(args)
    @importer = args[ :database]
    # @importer.import if manual_import
  end

  def visited(user)
    @importer.get_visit_count(user)
  end

  def were_visited(user)
    @importer.get_visitor_count(user)
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

  def last_visited(match_name)
    result = @importer.get_my_last_visit_date(match_name)
    if result >1
      Time.at(result).ago.to_words
    else
      "never"
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
