require 'rubygems'
require 'csv'
require 'set'
require_relative 'OutputScrape.rb'

class ImportData

  def initialize(username)
    @names = Hash.new {|h, k| h[k] = 0 }
    # @username = ARGV[0].to_s
    @username = username
    @storeCounts = OutputScrape.new
    @storeCounts.file = @username + "_count.csv"
    @storeCounts.clear
  end

  def loadData


    # begin
    #   #load count file data
    #   CSV.foreach(@username + "_count.csv", :headers => true, :skip_blanks => false) do |row|
    #     text = row[0]
    #     count = row[1].to_i
    #     @names[text] = count
    #   end
    # rescue
    #if count file not found, build one from log files
    CSV.foreach(@username.to_s + ".csv", :headers => true, :skip_blanks => false) do |row|
      text = row[0]
      @names[text] += 1
      # puts puts text + ": " + names[text].to_s
    end
    # end
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


  puts "Importing..."
  loadData
  saveData(@names)
  puts "Finished."
