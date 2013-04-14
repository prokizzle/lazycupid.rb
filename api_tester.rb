require './includes'


foo = Array.new
browser = Session.new(:username => ARGV[0], :password => ARGV[1])
app = EventWatcher.new(:browser => browser)
puts "Logging in..."
app.login
20.times do
  puts app.new_mail
  sleep 4
end
puts foo
app.logout
