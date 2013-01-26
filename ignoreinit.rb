require './DataManager'

@dataman = DataReader.new(ARGV[0])
puts "1 "
@dataman.load
@dataman.import
puts "2 "
@dataman.ignore_init
puts "3 "
@dataman.save
puts @dataman.ignore