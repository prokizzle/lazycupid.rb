# @config       = LazyCupid::Settings.new(username: "***REMOVED***", path: config_path)

namespace :db do
  task :create do
    result = %x{createdb lazy_cupid}
  end

  task :reinstall do
    %x{gem uninstall pg && bundle install}
  end

  task :backup do
    backup = %x{pg_dump lazy_cupid > db/backup/dump.sql}
  end

  task :populate_distances do
    config_path = File.expand_path("../config/", __FILE__)
    @db.fix_blank_distance
  end

  task :visit_times do
    times = Hash.new(0)
    IncomingVisit.each do |v|
      times[v[:server_gmt].hour] += 1 rescue nil
    end
    puts times
  end

  task :import_from_heroku do
    puts "- Capturing Heroku postgres backup snapshot"
    %x{heroku pgbackups:capture --app ***REMOVED***}
    puts "- Dumping database"
    %x{curl -o latest.dump `heroku pgbackups:url --app ***REMOVED***`}
    puts "- Importing database into localhost"
    %x{pg_restore --verbose --clean --no-acl --no-owner -h localhost -U ***REMOVED*** -d lazy_cupid latest.dump}
  end

task :tasks do
  username = ask("Username:  ")
  config_path = File.expand_path("../config/", __FILE__)
  @config       = LazyCupid::Settings.new(username: username, path: config_path)
  @db           = LazyCupid::DatabaseMgr.new(login_name: username, settings: @config)
  @db.db_tasks
end

# task :migrate {%x{sequel -m db/migrations/ -E #{$db_url}}}
end
