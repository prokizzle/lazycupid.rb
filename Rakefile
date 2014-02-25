require_relative 'lib/LazyCupid/database_manager'
require_relative 'lib/LazyCupid/settings'
config_path = File.expand_path("../config/", __FILE__)

@config       = LazyCupid::Settings.new(username: "***REMOVED***", path: config_path)

@db           = LazyCupid::DatabaseMgr.new(login_name: "***REMOVED***", settings: @config)

require_relative 'lib/LazyCupid/models'
require 'highline/import'
require 'progress_bar'
namespace :db do
  @config       = LazyCupid::Settings.new(username: "***REMOVED***", path: config_path)
  # @db           = LazyCupid::DatabaseMgr.new(login_name: "***REMOVED***", settings: @config)

  task :migrate do
    result = %x{sequel -m db/migrations/ -E #{$db_url}}
                puts result
                end

                task :reinstall do
                  %x{gem uninstall pg && bundle install}
                end

                task :create do
                  result = %x{createdb lazy_cupid}
                end

                task :tasks do
                  username = ask("Username:  ")
                  config_path = File.expand_path("../config/", __FILE__)
                  @config       = LazyCupid::Settings.new(username: username, path: config_path)
                  @db           = LazyCupid::DatabaseMgr.new(login_name: username, settings: @config)
                  @db.db_tasks
                end

                task :populate_distances do
                  config_path = File.expand_path("../config/", __FILE__)
                  @db.fix_blank_distance
                end

                task :backup do
                  backup = %x{pg_dump lazy_cupid > db/backup/dump.sql}
                end

                task :update_counts do
                  t = OutgoingVisit.all
                  t.each do |visit|
                    puts "#{visit[:account]}: #{visit[:name]}"
                    Match.where(:account => visit[:account], :name => visit[:name]).update(:counts => Sequel.expr(1) + :counts)
                  end
                end

                task :copy_ages do


                  m = Match.where(:ages => 25).order(:name)

                  m.each do |user|
                    u = user.to_hash
                    puts "Updating ages for #{u[:name]}"
                    Match.where(:name => u[:name]).update(:ages => u[:age].to_i)
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
                  Stat.distinct(:account).each do |s|
                    puts s.to_hash
                  end
                  # puts accounts.to_a
                  # puts "Storing totals..."
                  # accounts = accounts.to_a
                  # accounts.each do |account|
                    # visits = OutgoingVisit.where(account: account).count
                    # Stat.where(account: account).update(total_visits: visits)
                    # puts account
                    # p account
                  # end
                end

                task :all_visits do
                  puts IncomingVisit.all.count
                  IncomingVisit.each do |v|
                    puts v.to_hash
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



                task :join do


                  puts Match.where(:account => "***REMOVED***", :name => "***REMOVED***")

                end

                task :lookup do
                  username = ask("username: ") {|q| echo = true}
                  account = ask("account: ") {|q| echo = true}
                  puts "#{Match.where(account: account, name: username).first[:counts]} visits"
                  OutgoingVisit.where(account: account, name: username).each do |i|
                    puts Time.at(i.to_hash[:timestamp].to_i)

                  end
                end

                task :ddv do
                  @prev = ""
                  IncomingVisit.distinct.each do |v|
                    # if v.to_hash[:server_seqid] == @prev
                    #   v.delete
                    #   puts "Deleted duplicate"
                    # end
                    # v.to_hash[:server_seqid] = @prev
                    # IncomingVisit.where(server_seqid: )
                  end
                end

                task :any_counts do
                  puts Match.filter(:account => "***REMOVED***", :last_visit => 0).first.to_hash
                end

                task :fix_match_percents do
                  Match.where(:match_percent => nil).update(:match_percent => 100)
                end

                task :import_from_heroku do
                  puts "- Capturing Heroku postgres backup snapshot"
                  %x{heroku pgbackups:capture --app ***REMOVED***}
                  puts "- Dumping database"
                  %x{curl -o latest.dump `heroku pgbackups:url --app ***REMOVED***`}
                  puts "- Importing database into localhost"
                  %x{pg_restore --verbose --clean --no-acl --no-owner -h localhost -U ***REMOVED*** -d lazy_cupid latest.dump}
                end
                end
