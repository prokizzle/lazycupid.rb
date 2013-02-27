require './includes'

class Roller
  attr_accessor :username, :password, :speed
  attr_reader :username, :password, :speed


  def initialize(args)
    @username = args[ :username]
    @password = args[ :password]
    @speed = speed
    @browser = Session.new(:username => self.username, :password => self.password)
    @db = DatabaseManager.new(:login_name => self.username)
    @blocklist = BlockList.new(:database => self.db, :browser => @browser)
    @search = Lookup.new(:database => self.db)
    @display = Output.new(:stats => @search, :username => self.username)
    @user = Users.new(:database => self.db, :browser => @browser)
    @harvester = Harvester.new(:browser => @browser, :database => self.db, :user_stats => @user)
    @smarty = SmartRoll.new(:database => self.db, :blocklist => self.blocklist, :harvester => @harvester, :user_stats => @user, :browser => @browser, :gui => @display)
  end

  def fix_dates
    @smarty.fix_blank_dates
  end

  def blocklist
    @blocklist
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
    @db
  end

  def visit_newbs
    @smarty.run2
  end

  def ignore_user(user)
    @blocklist.add(user)
  end

  def gender_fix(d)
    @smarty.gender_fix(d)
  end

  def smart_roller(max)
    @smarty.max = max
    @smarty.run
  end

  def ignore_hidden_users
    @blocklist.import_hidden_users
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

  def harvest_home_page
    @harvester.scrape_home_page
  end

  def login
    @browser.login
  end

  def add(user)
    @db.add_new_match(user)
    @db.save
  end

  def range_roll(min, max)
    @smarty.run_range(min, max)
  end

  def check_visitors
    @harvester.visitors
  end

  def test_user_object(user)
    @browser.go_to("http://www.okcupid.com/profile/#{user}/")
    puts @user.handle
    puts @user.age
    puts @user.sexuality
    puts @user.handle
    puts @user.city
    puts @user.state
    puts @user.gender
    puts @user.relationship_status
    puts @user.match_percentage
  end


  def scrape_similar(user)
    @harvester.similar_user_scrape(user)
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
  puts "(1) Smart Mode"
  puts "(2) Visit new users"
  puts "(3) Monitor Visitors"
  puts "(a) Admin menu"
  puts "(Q) Quit",""
  print "Mode: "
  mode = gets.chomp

  case mode
  when "1"
    print "Max: "
    max = gets.chomp
    # print "MPH: "
    # mph = gets.chomp
    application.smart_roller(max.to_i)
  when "2"
    application.smart_roller(0)
  when "3"
    application.check_visitors_loop
  when "4"
    puts "User: "
    user = gets.chomp
    application.scrape_similar(user)
  when "5"
    application.visit_newbs
  when "6"
    print "Min: "
    min = gets.chomp
    print "Max: "
    max = gets.chomp
    application.range_roll(min, max)
  when "7"
    application.harvest_home_page
  when "a"
    puts "Admin Menu","-----"
    puts "(1) Add User"
    puts "(2) Lookup visit counts"
    puts "(3) Block user"
    puts "(4) Auto import hidden users to blocklist"
    puts "(5) Populate blank genders"
    choice = gets.chomp
    case choice
    when "1"
      print "User to add: "
      user = gets.chomp
      application.add_user(user)
    when "2"
      puts ""
      print "User: "
      user = gets.chomp
      print "You have visited #{user} "
      puts application.search(user).to_s + " times."
      sleep 5
    when "3"
      print "User: "
      user = gets.chomp
      application.ignore_user(user)
    when "4"
      application.ignore_hidden_users
    when "5"
      application.gender_fix(5)
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
puts ""
