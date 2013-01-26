#!/usr/bin/env ruby
require './SmartRoll'
require './Session'

class SmartStalker

def initialize(username, password, max)
    @database = DataReader.new(username)
    @search = Lookup.new(username)
    @profile = Session.new(username, password)
    @display = Output.new(username)
    @roller = AutoRoller.new(username, password)
    @smarty = SmartRoll.new(database, roller, max)
    @database.load
    @profile.login
end

def run
    @smarty.run
end

end

print "Username: "
username = gets.chomp
puts ""
print "Password: "
password = gets.chomp
puts ""
print "Max: "
max = gets.chomp


application = SmartStalker.new(username, password, max)
application.run

