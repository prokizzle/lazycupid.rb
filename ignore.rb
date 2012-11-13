 require_relative 'AutoRoller.rb'

  lazyCupid = AutoVisitor.new()
  lazyCupid.username = "***REMOVED***"
  lazyCupid.ignoreUser "#{ARGV[0]}"
  puts "#{ARGV[0]} added to #{lazyCupid.username}'s ignore list"