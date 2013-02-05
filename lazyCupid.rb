require './AutoRoller'
require './DataManager'
require './Output'
require './lookup'
require './Session'
require './SmartRoll'
require './BlockList'
require './Harvester'

class Roller
  attr_accessor :username, :password, :speed
  attr_reader :username, :password, :speed


  def initialize(args)
    @username = args[ :username]
    @password = args[ :password]
    @speed = speed
    @database = DataReader.new(:username => @username)
    @search = Lookup.new(@database)
    @profile = Session.new(:username => self.username, :password => self.password)
    @display = Output.new(@search, @username)
    @roller = AutoRoller.new(@database, @profile, @display)
    @smarty = SmartRoll.new(@database, @roller)
    @blocklist = BlockList.new(@database)
    @harvester = Harvester.new(:browser => @profile, :database => @database)
  end

  def username
    @username
  end

  def clear
    @display.clear
  end

  def password
    @password
  end

  def block(user)
    @blocklist.add(user)
  end

  def harvester(speed)
    @roller.mph = speed.to_i
    @roller.run
  end

  def smart_roller(max, mph=600)
    @smarty.max = max
    @smarty.mph = mph
    @smarty.run
  end

  def search(user)
    @search.byUser(user)
  end

  def logout
    @profile.logout
  end

  def logged_in
    @profile.is_logged_in
  end

  def login
    @profile.login
  end

  def load_data
    @database.load
  end

  def harvest
    @harvester.run
  end

  def check_visitors
    @harvester.visitors
  end

end

puts "LazyCupid Main Menu","--------------------",""
puts "Please login.",""

quit = false
logged_in = false

begin
while logged_in == false
  print "Username: "
  username = gets.chomp
  print "Password: "
  password = gets.chomp
  application = Roller.new(:username => username, :password => password)
  if application.login
    logged_in = true
    application.load_data
  else
    puts "Incorrect password. Try again.",""
  end
end
rescue SystemExit, Interrupt
quit = true
logout = false
puts "","","Goodbye."
end

while quit == false
  application.check_visitors
  application.clear
  puts "LazyCupid Main Menu","--------------------","#{username}",""
  puts "Choose Mode:"
  puts "(1) Blind Mode (Harvest)"
  puts "(2) Smart Mode"
  puts "(3) Lookup counts"
  puts "(4) Add to ignore list"
  puts "(5) Harvest"
  puts "(Q) Quit",""
  print "Mode: "
  mode = gets.chomp

  case mode
  when "1"
    print "Speed: "
    speed = gets.chomp
    application.harvester(speed.to_i)
  when "2"
    print "Max: "
    max = gets.chomp
    # print "MPH: "
    # mph = gets.chomp
    application.smart_roller(max.to_i)
  when "3"
    puts ""
    print "User: "
    user = gets.chomp
    print "You have visited #{user} "
    puts application.search(user).to_s + " times."
    sleep 5
  when "4"
    print "User: "
    user = gets.chomp
    application.block(user)
  when "5"
    application.harvest
  when "6"
    application.check_visitors
  when "q"
    quit = true
  when "Q"
    quit = true
  else
    puts "Invalid selection."
  end
end
if logout == true
application.logout
application.clear
end
application.clear
puts ""
