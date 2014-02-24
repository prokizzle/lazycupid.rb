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

                task :join do


                  puts Match.where(:account => "***REMOVED***", :name => "***REMOVED***")

                end

                task :lookup do
                  username = ask("username: ") {|q| echo = true}
                  account = ask("account: ") {|q| echo = true}
                  OutgoingVisit.where(account: account, name: username).each do |i|
                    puts Time.at(i.to_hash[:timestamp].to_i)
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
