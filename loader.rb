require 'rubygems'
require_relative 'ImportData.rb'

@loader = ImportData.new(ARGV[0])
# ImportData.username = ARGV[0].to_s
@loader.loadData
@loader.saveData