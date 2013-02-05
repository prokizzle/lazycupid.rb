require './includes.rb'

@database = DataReader.new(ARGV[0])
@database.import
@database.load
@database.ignore_init
@database.zindex_init
@database.visit_count_init
@database.save