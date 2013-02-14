require './includes'

class Roller
  attr_accessor :username, :password, :speed
  attr_reader :username, :password, :speed


  def initialize(args)
    @username = args[ :username]
    @password = args[ :password]
    @speed = speed
    @browser = Session.new(:username => self.username, :password => self.password)
    @database = DataReader.new(:username => self.username)
    @search = Lookup.new(:database => self.db)
    @display = Output.new(:stats => @search, :username => self.username)
    @roller = AutoRoller.new(:database => self.db, :browser => @browser, :gui => @display)
    @smarty = SmartRoll.new(:database => self.db, :visitor => @roller)
    @blocklist = BlockList.new(:database => self.db)
    @harvester = Harvester.new(:browser => @browser, :database => self.db)
    @admin = Admin.new(:database => self.db)
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

  def db
    @database
  end

  def ignore_user(user)
    @blocklist.ignore_user(user)
  end

  def harvester(speed)
    @roller.mph = speed.to_i
    @roller.run
  end

  def smart_roller(max, mph=600)
    @smarty.mode = "c"
    @smarty.max = max
    @smarty.mph = mph
    @smarty.run
  end

  def smart_roller_by_visit(days)
    @smarty.mode = "v"
    @smarty.days = days
    @smarty.mph = 600
    @smarty.run
  end

  def overkill(min)
    @smarty.mode = "k"
    @smarty.max = min
    @smarty.mph = 600
    @smarty.run
  end

  def search(user)
    @search.byUser(user)
  end

  def logout
    @browser.logout
  end

  def logged_in
    @browser.is_logged_in
  end

  def login
    @browser.login
  end

  def load_data
    @database.load
  end

  def add(user)
    @database.add_new_match(user)
    @database.save
  end

  def harvest(num=50)
    @harvester.number = num
    @harvester.run
  end

  def check_visitors
    @harvester.visitors
  end

  def check_visitors_loop
    puts "Monitoring visitors"
    begin
      loop do
        @harvester.visitors
        sleep 60
      end
    rescue SystemExit, Interrupt
    end
  end

  def admin_menu
    @admin.menu
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
    password = ask("password: ") { |q| q.echo = false }
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
  puts "(3) Visit new users"
  puts "(4) Harvest"
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
    application.load_data
    application.harvest(25)
    application.smart_roller(0)
  when "4"
    application.harvest
  when "5"
    puts "Min: "
    min = gets.chomp
    application.overkill(min)
  when "6"
    application.check_visitors_loop
  when "8"
    print "User to add: "
    user=gets.chomp
    application.add(user)
  when "9"
    print "Days: "
    days =gets.chomp
    application.smart_roller_by_visit(days)
  when "a"
    puts "Admin Menu","-----"
    puts "(1) Add User"
    puts "(2) Rebuild database"
    puts "(3) Lookup visit counts"
    puts "(4) Block user"
    choice = gets.chomp
    case choice
    when "1"
      print "User to add: "
      user = gets.chomp
      self.add_user(user)
    when "2"
      self.import
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
      application.ignore_user(user)
    end
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
