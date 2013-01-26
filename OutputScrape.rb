require 'csv'

class CSVWriter
  attr_accessor :mode, :data
  attr_reader :mode, :data

  def write(file, mode, data)
    CSV.open(file, mode) do |csv|
      csv << data
    end
  end

end


class OutputScrape

  attr_accessor :file, :data
  attr_reader :file, :data

  def initialize(file="output.csv")
    @data = Array.new
    @file = file
    @writer = CSVWriter.new
  end

  def append
    @writer.write(@file, "ab", @data)
  end

  def clear
    @writer.write(@file,"wb", [])
  end

  def new
    clear
  end

  def write(mode, data)
    CSV.open(@file, mode) do |csv|
      csv << data
    end
  end

end

class DataWriter <OutputScrape
end