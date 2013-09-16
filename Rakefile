namespace :db do
  task :migrate do
    result = %x{sequel -m db/migrations/ -E postgres://localhost/lazy_cupid}
    puts result
  end

  task :create do
    result = %x{createdb lazy_cupid}
  end

  require 'highline/import'
  require_relative 'lib/LazyCupid/database_manager'
  require_relative 'lib/LazyCupid/settings'
  task :tasks do
    username = ask("Username:  ")
    config_path = File.expand_path("../config/", __FILE__)
    @config       = LazyCupid::Settings.new(username: username, path: config_path)
    @db           = LazyCupid::DatabaseMgr.new(login_name: username, settings: @config)
    @db.db_tasks
  end

  task :populate_distances do
    config_path = File.expand_path("../config/", __FILE__)
    @config       = LazyCupid::Settings.new(username: "***REMOVED***", path: config_path)
    @db           = LazyCupid::DatabaseMgr.new(login_name: "***REMOVED***", settings: @config)
    @db.fix_blank_distance
  end

  task :backup do
    backup = %x{pg_dump lazy_cupid > db/backup/dump.sql}
  end
end
