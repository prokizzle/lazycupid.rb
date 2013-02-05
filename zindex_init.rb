require './includes.rb'

@database = DataReader.new(ARGV[0])
@database.import
@database.load
@database.zindex_init
@database.save