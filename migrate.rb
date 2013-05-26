require 'sqlite3'
require './includes'

@login = ARGV.shift
config_path   = File.dirname($0) + '/config/'
log_path      = File.dirname($0) + '/logs/'
@db_path      = File.dirname($0) + '/db/'
@log          = Logger.new("logs/#{@login}_#{Time.now}.log")
@config       = Settings.new(username:  @login, path:  config_path)

@old_db = SQLite3::Database.new( "./db/#{@login}.db" )
@new_db = DatabaseMgr.new(login_name: @login, settings: @config)
begin
  @old_db.execute("alter table matches add column does_exist integer")
rescue
end
# @old_db.execute("update matches set does_exist = 0 where exists is null")

matches = @old_db.execute("select name, counts, gender, age, distance, last_visit from matches where (does_exist = 0 or does_exist is null)")
@bar = ProgressBar.new(matches.size)

matches.each do |name, counts, gender, age, distance, last_visit|
  if gender == "M" or gender == "F"
    @bar.increment!
    unless @new_db.existsCheck(name)
      @new_db.import_user(name: name, age: age, gender: gender, distance: distance, last_visit: last_visit, counts: counts)
      @old_db.execute("delete from matches where name=?", name)
    else
      @old_db.execute("update matches set does_exist = 1 where name = ?", name)
    end
  end
end
matches = @old_db.execute("select name, counts, gender, age, distance, last_visit from matches where does_exist = 1")
matches.each do |name, counts|
  if counts > 0
    @new_db.increment_visit_count(name)
    @old_db.execute("delete from matches where name=?", name)
  end
end
