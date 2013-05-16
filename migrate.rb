require 'sqlite3'
require './includes'

@login = ARGV.shift
config_path          = File.dirname($0) + '/config/'
log_path      = File.dirname($0) + '/logs/'
@db_path      = File.dirname($0) + '/db/'
@log          = Logger.new("logs/#{@login}_#{Time.now}.log")
@config       = Settings.new(:username => @login, :path => config_path)



# DB = Sequel.connect("sqlite://localhost/db/#{@login}.db"
@old_db = SQLite3::Database.new( "./db/#{@login}.db" )
@new_db = DatabaseMgr.new(:login_name => @login, :settings => @config)
# @matches = DB[:matches]

matches = @old_db.execute("select name, counts, gender, age, distance, last_visit from matches")
@bar = ProgressBar.new(matches.size)
@c = 0
# until matches.size == 0
#   match = matches.shift
#   name = match.shift
#   counts = match.shift
#   gender = match.shift
  # age = match.sh
matches.each do |name, counts, gender, age, distance, last_visit|
  if gender == "M" or gender == "F"
    # if @c >= 1000
    #   @old_db.execute("vacuum")
    #   @c = 0
    # end
    # puts name.to_s
    @bar.increment!

    unless @new_db.existsCheck(name)
      @new_db.import_user(name: name, age: age, gender: gender, distance: distance, last_visit: last_visit, counts: counts)
      @old_db.execute("delete from matches where name=? and account=?", name, @login)
      # @c += 1
    end
  end
end

# bar = ProgressBar.new(matches.size)
#   until matches.size == 0

#     500.times do
#       temp = matches.shift
#       name = temp[0]
#       counts = temp[1]
#       gender = temp[2]
#       age = temp[3]
#       distance = temp[4]
#       last_visit = temp[5]


#       unless @new_db.existsCheck(name)
#         @new_db.import_user(name: name, age: age, gender: gender, distance: distance, last_visit: last_visit, counts: counts)
#         @old_db.execute("delete from matches where name=? and account=?", name, @login)
#         @c += 1
#       end
#       bar.increment!
#     end
#     matches = @old_db.execute("select name, counts, gender, age, distance, last_visit from matches")
#   end

# end
