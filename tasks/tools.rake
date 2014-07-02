task :driving_distance do
  require 'rest-client'
  matches = Match.where(:driving_duration => 0, :account => "***REMOVED***")
  puts matches.to_a.size
  matches.each do |match|
    begin
      city = URI.encode(match[:city])
      state = match[:state]

      result = JSON.parse(RestClient.get "http://maps.googleapis.com/maps/api/distancematrix/json?origins=78704&destinations=#{city}+#{state}&mode=driving&sensor=false").to_hash
      distance = result["rows"].first["elements"].first["distance"]["value"].to_i
      duration = result["rows"].first["elements"].first["duration"]["value"].to_i
      Match.where(account: $login, name: match[:name]).update(driving_distance: distance, driving_duration: duration)
      # puts "#{match[:name]}: #{(distance.to_f*0.000621371).to_i} miles"
    rescue Exception => e
      puts e.message
      puts result
    end
  end
end

task :city_msg do
  require 'launchy'
  city = ask("city: ")
  myaccount = ask("account: ")
  result = IncomingMessage.join_table(:left, :matches, :name => :username).distinct(:username).filter(Sequel.like(:city, "%#{city}"))
  result.each do |m|
    puts m.to_hash[:username] #if m.to_hash[:account] == myaccount
    Launchy.open "http://okcupid.com/profile/#{m.to_hash[:username]}"
    sleep 5
  end

end

task :analyzer do
  require_relative 'browser'
  require 'highline/import'

  username = ask("username: ")
  password = ask("password: "){ |q| q.echo = "*" }
  rk = "***REMOVED***"

  t = LazyCupid::TextClassification.new(read_key: rk)
  b = LazyCupid::Browser.new(username: username, password: password)
  b.login
  loop do
    puts ""
    user = ask("user: ")
    url = "http://www.okcupid.com/profile/#{user}"

    browser               = b
    request_id            = (1..266).to_a.sample

    browser.send_request(url, request_id)

    print "Requesting profile..."
    resp = {ready: false}
    until resp[:ready] == true
      resp = browser.get_request(request_id)
      # p resp
    end
    puts " done."


    mood = t.fetch("mood", resp)
    gender = t.fetch("gender", resp)
    sentiment = t.fetch("sentiment", resp)
    topics = t.fetch("topics", resp)
    age = t.fetch("age", resp)
    values = t.fetch("values", resp)
    classics = t.fetch("classics", resp)
    he = gender == "female" ? "she" : "he"
    his = gender == "female" ? "her" : "his"
    emo = t.fetch("emo", resp)

    print "#{user} is a #{values} #{gender}, "
    print "who values #{topics}, is generally #{sentiment}, "
    print "was #{mood} when #{he} wrote #{his} profile, "
    puts "acts like #{he} is #{age} and writes like #{classics}"
    puts "emo: #{emo}"
  end
end
task :username_changes do
  changes = UsernameChange.all
  changes.each do |change|
    results = []
    c = 1
    old_name = change.to_hash[:old_name]
    results << old_name
    until c == 0
      c = 0
      second = ""
      if additional_name_change(old_name) && !(results.include? additional_name_change(old_name))

        results << additional_name_change(old_name)

        old_name = results.last
        c = 1
      end
    end
    if results.size > 2
      output = ""
      results.each { |n| output += " -> #{n}" }
      puts output
    end
  end
end

task :change_state do
  puts Match.where(account: "***REMOVED***", state: "TX").to_a.size
  # puts Match.where(account: "***REMOVED***", state: state_a).update(distance: d)
  # puts Match.where(account: "***REMOVED***", state: state_b).update(distance: d)
end
