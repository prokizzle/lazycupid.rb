require_relative 'lib/LazyCupid/database_manager'
require_relative 'lib/LazyCupid/settings'
require 'chronic'
require 'progress_bar'
require 'highline/import'


@db = LazyCupid::DatabaseMgr.new(login_name: "***REMOVED***", settings: LazyCupid::Settings.new(username: "***REMOVED***", path: File.expand_path("../config/", __FILE__)))

require_relative 'lib/LazyCupid/models'
Dir.glob('tasks/*.rake').each {|r| import r }
