require 'sqlite3'
require './includes'

@login = ARGV.shift
config_path          = File.dirname($0) + '/config/'
log_path      = File.dirname($0) + '/logs/'
@db_path      = File.dirname($0) + '/db/'
@log          = Logger.new("logs/#{@login}_#{Time.now}.log")
@config       = Settings.new(:username => @login, :path => config_path)



# DB = Sequel.connect("sqlite://localhost/db/#{@login}.db"
@db = SQLite3::Database.new( "./db/#{@login}.db" )
@new_db = DatabaseMgr.new(:login_name => @login, :settings => @config)
# @matches = DB[:matches]

matches = @db.execute("select name, counts, gender, age, distance, last_visit from matches")
    @bar = ProgressBar.new(matches.size)
matches.reverse_each do |name, counts, gender, age, distance, last_visit|
  if gender == "M" or gender == "F"
    # puts name.to_s
    @bar.increment!
    @new_db.add_user(name, gender)
    @new_db.set_distance(username: name, distance: distance)
    @new_db.set_age(name, age)
    @new_db.set_my_last_visit_date(name, last_visit)
    @db.execute("delete from matches where name=? and account=?", name, @login)
  end
end
