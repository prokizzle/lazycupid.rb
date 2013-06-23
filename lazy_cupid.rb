require_relative 'lib/includes.rb'

if ARGV[0] == "-i"
  puts "Interactive Mode"
  app = Main.new
  app.login
  app.menu
else
  app = Main.new
  app.login
  app.run
end
