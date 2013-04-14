require './includes'


foo = Array.new
browser = Session.new(:username => "danceyrselfcln", :password => "123457")
app = EventWatcher.new(:browser => browser)
puts "Logging in..."
app.login
20.times do
  puts app.new_mail
  sleep 4
end
puts foo
app.logout
