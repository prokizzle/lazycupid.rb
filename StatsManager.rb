class StatsManager
  def lastVisited(match_name)
    CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
      text = row[0]
      if text == match_name
        @date = row[2].to_s
      else
        @date = "N/a"
      end
    end
    puts @date
  end

  def compileStats(s, names)
    jew = names.sort_by {|a, b| b.to_i }
    @storeCounts = DataWriter.new
    @storeCounts.file = @username + "_count.csv"
    @storeCounts.clear
    s.each do |a|
      row = [a, a.size]
      @storeCounts.data = row
      @storeCounts.append
    end
  end

end