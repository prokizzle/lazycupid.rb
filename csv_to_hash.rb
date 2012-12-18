require 'rubygems'
require 'csv'
require 'set'
require_relative 'OutputScrape.rb'

class ImportData

  def init(username)
    @names = Hash.new {|h, k| h[k] = 0 }
    # @username = ARGV[0].to_s
    @username = username
    @storeCounts = OutputScrape.new
    @storeCounts.file = @username + "_count.csv"
    @storeCounts.clear
  end

  def loadData
    CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
      text = row[0]
      @names[text] += 1
    end
  end

  def saveData(names)
    @names.each do |a, b|
      row = [a, b]
      @storeCounts.data = row
      @storeCounts.append
      # puts row
    end
  end

  def sortData
    @names.each do |a,b|
    end
  end

  def run
    loadData
    saveData(@names)
  end
end

application = ImportData.new
application.init(ARGV[0])
application.run
