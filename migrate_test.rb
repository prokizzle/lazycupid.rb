require_relative 'lib/LazyCupid/sequel_manager'
require_relative 'lib/LazyCupid/settings'
username = ARGV[0]
config_path   = File.dirname($0) + '/config'
@config       = LazyCupid::Settings.new(username: username, path: config_path)


runner = LazyCupid::DatabaseManager.new(login_name: username, settings: @config)
# runner.migrate
# runner.accounts.where(:account => username).each {|r| p r}
p runner.test_users.each {|r| puts r}