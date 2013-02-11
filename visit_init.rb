require './includes.rb'

@database = DataReader.new(:username => ARGV[0])
@database.import