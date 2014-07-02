namespace :match do
  task :delete do
    puts Match.where(account: "***REMOVED***", name: ask("Username: ")).delete
  end
end

task :fix_match_percents do
  Match.where(:match_percent => nil).update(:match_percent => 100)
end

task :lookup do
  username = ask("username: ") {|q| echo = true}
  account = ask("account: ") {|q| echo = true}
  puts "#{Match.where(account: account, name: username).first[:counts]} visits"
  OutgoingVisit.where(account: account, name: username).each do |i|
    puts Time.at(i.to_hash[:timestamp].to_i)
  end
  puts Match.where(name: username, account: account).first.to_hash
end
