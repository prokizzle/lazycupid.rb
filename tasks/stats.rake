task :distinct_accounts do
  Stat.distinct(:account).each do |s|
    puts s.to_hash
  end
end

task :set_counts do
  require 'set'
  accounts = Set.new
  puts "Gathering account names..."
  # Match.all.each do |m|
  # accounts.add(m.to_hash[:account].to_s)
  # end
  Match.distinct(:account).to_a.each do |m|
    Stat.find_or_create(account: m[:account]).update(
      total_visits: OutgoingVisit.where(account: m[:account]).count,
      total_visitors: IncomingVisit.where(account: m[:account]).count,
      new_users: Match.where(account: m[:account]).count,
      total_messages: IncomingMessage.where(account: m[:account]).count
    )
  end
end

task :stats do
  account = ask("account: ")
  Stat.find_or_create(account: account).update(
    total_visits: OutgoingVisit.where(account: account).count,
    total_visitors: IncomingVisit.where(account: account).count,
    new_users: Match.where(account: account).count,
    total_messages: IncomingMessage.where(account: account).count
  )
  stat = Stat.where(account: account)
  puts "Success rate: #{stat.to_hash[:total_messages]/stat.to_hash[:total_visits]}%"
                end
