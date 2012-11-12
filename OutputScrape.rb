class OutputScrape

  attr_accessor :file
  attr_accessor :data

  def initialize(file="output.csv")
    @data = Array.new
    @file = file
  end

  def append
    CSV.open(@file, 'ab') do |csv|
      csv << @data
    end
  end

  def clear
    empty = Array.new
    CSV.open(@file, 'wb') do |csv|
      csv << empty
    end
  end
end