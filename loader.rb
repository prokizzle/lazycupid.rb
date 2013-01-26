require 'rubygems'
require_relative 'DataManager.rb'

@loader = DataReader.new(ARGV[0])
# ImportData.username = ARGV[0].to_s
@loader.loadData
@loader.saveData