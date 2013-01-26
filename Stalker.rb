def stalk(user, times)
  puts "Stalk Mode","-------------","User: " + user.to_s

  i=1
  # until (i==times.to_i)
  5.times do
    rollDice("http://www.okcupid.com/profile/#{user}/")
    sleep 30000
  end
end