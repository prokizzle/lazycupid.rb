require 'sqlite3'

class DatabaseManager

  def initialize(args)
    login = args[ :login_name]
    open_db(login)


  end

  def open_db( db )
    begin
      @db = SQLite3::Database.new( "#{db}" )
    rescue
    end

  end

  def import


  end

  def get_match_names
    @db.execute( "select name from matches" )
  end

  def get_visit_count(user)
    row = @db.execute( "select count from matches where name= ? ", user)
    row[0][0].to_i
  end

  def get_last_visit_date(user)
    result = @db.execute( "select last_visit from matches where name=?", user)
    result[0][0].to_i
  end

  def update_visit_count(match_name, number)
    @db.execute( "update matches set count=? where name=?", number, match_name )
  end

  def filter_by_visits(max, min=0)
    @db.execute( "select name from matches where count between ? and ?", min, max )
  end

  def filter_by_dates(min=0, max)
    @db.execute( "select name from matches where last_visit between ? and ?", min, max)
  end

  def user_record_exists(user)
    @db.execute( "select exists(select * from matches where name=" + user )
  end

  def log(match_name, match_percent=0)
    if existsCheck(match_name)
      count = self.get_visit_count(match_name) + 1
      self.update_visit_count(match_name, count)
    else
      self.add_user(match_name)
    end
  end

  def add_user(username, count=1)
    if !(existsCheck(username))
      @db.execute( "insert into matches(name, count) values (?, ?)", username, count)
    end
  end

  def delete_user(username)
    if existsCheck(username)
      @db.execute( "delete from matches where name=?", username)
    end
  end

  def is_ignored(username)
    @db.execute( "select ignore from matches where name=?", username)
  end

  def send_command(command)
    @db.execute( "?", command)
  end

  def ignore_user(username)
    @db.execute( "update matches set ignore=true where name=?", username)
  end

  def unignore_user(username)
    @db.execute( "update matches set ignore=false where name=?", username)
  end

  def existsCheck( id )
    temp = @db.execute( "select 1 where exists(
          select 1
          from matches
          where name = ?
      ) ", [id] ).any?
  end

  def close
    @db.close
  end

end

app = DatabaseManager.new(:login_name => "***REMOVED***")
puts app.log("CyanideLady2")
puts app.get_visit_count("CyanideLady2")
app.delete_user("CyanideLady2")
app.log("CyanideLady2")
puts app.get_visit_count("CyanideLady2")
