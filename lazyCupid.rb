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
    @prefs = Preferences.new(:browser => @browser)
    @blocklist = BlockList.new(:database => self.db, :browser => @browser)
    @search = Lookup.new(:database => self.db)
    @display = Output.new(:stats => @search, :username => self.username)
    @user = Users.new(:database => self.db, :browser => @browser)
    @harvester = Harvester.new(:browser => @browser, :database => self.db, :user_stats => @user)
    @smarty = SmartRoll.new(:database => self.db, :blocklist => self.blocklist, :harvester => @harvester, :user_stats => @user, :browser => @browser, :gui => @display)
  end

  def fix_dates
    self.open_db
    @smarty.fix_blank_dates
    self.close_db
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
    self.open_db
    @smarty.run2
    self.close_db
  end

  def ignore_user(user)
    self.open_db
    @blocklist.add(user)
    self.close_db
  end

  def gender_fix(d)
    self.open_db
    @smarty.gender_fix(d)
    self.close_db
  end

  def smart_roller(max)
    self.open_db
    @smarty.max = max
    @smarty.run
    self.close_db
  end

  def close_db
    puts "Debug: Closing database."
    db.close
  end

  def open_db
    puts "Debug: Opening database"
    db.open
  end

  def ignore_hidden_users
    self.open_db
    @blocklist.import_hidden_users
    self.close_db
  end

  def search(user)
    self.open_db
    @search.byUser(user)
    self.close_db
  end

  def logout
    @browser.logout
  end

  def logged_in
    @browser.is_logged_in
  end

  def harvest_home_page
    self.open_db
    @harvester.scrape_home_page
    self.close_db
  end

  def login
    @browser.login
  end

  def add(user)
    self.open_db
    @db.add_user(:username => user)
    self.close_db
  end

  def range_roll(args)
    self.open_db
    min = args[ :min_value]
    max = args[ :max_value]
    @smarty.run_range(min, max)
    self.close_db
  end

  def new_roll
    self.open_db
    @smarty.run_new_users_only
    self.close_db
  end

  def check_visitors
    self.open_db
    result = @harvester.visitors
    self.close_db
    result
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

  def test_prefs
    @prefs.get_match_preferences
  end


  def scrape_similar(user)
    self.open_db
    @harvester.similar_user_scrape(user)
    self.close_db
  end

  def check_visitors_loop
    self.open_db
    puts "Monitoring visitors"
    begin
      loop do
        puts "#{@harvester.visitors} new visitors"
        sleep 60
      end
    rescue SystemExit, Interrupt
    end
  self.close_db
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
  puts "#{application.check_visitors} new visitors"
  application.clear
  puts "LazyCupid Main Menu","--------------------","#{username}",""
  puts "Choose Mode:"
  puts "(1) Smart Mode"
  puts "(2) Visit new users"
  puts "(3) Monitor Visitors"
  puts "(4) Follow up"
  puts "(5) Scrape home page"
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
    application.new_roll
  when "3"
    application.check_visitors_loop
  when "4"
    application.range_roll(:min_value => 1, :max_value => 10)
  when "5"
    application.harvest_home_page
  when "7"
    application.visit_newbs
  when "6"
    puts "User: "
    user = gets.chomp
    application.scrape_similar(user)
  when "8"
    application.test_prefs
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
      application.add(user)
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
    @logout = true
    application.close_db
  when "Q"
    quit = true
    @logout = true
    application.close_db
  else
    puts "Invalid selection."
  end
end
if @logout == true
  application.logout
  application.clear
  application.close_db
end
puts ""
