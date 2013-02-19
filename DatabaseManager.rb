require 'sqlite3'

class DatabaseManager

  def initialize(args)
    login = args[ :login_name]
    open_db(login)


  end

  def open_db( db )
    begin
      @db = SQLite3::Database.new( "#{db}.db" )
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

  # def get_last_visit_date(user)
  #   result = @db.execute( "select last_visit from matches where name=?", user)
  #   result[0][0].to_i
  # end

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

  def set_match_percentage(user, match_percent)
    @db.execute("update matches set match_percent=? where name=?", user, match_percent)

  end

  def get_match_percentage(user)
    result = @db.execute("select match_percent from matches where name=?", user)
    result[0][0].to_i
  end

  def set_visitor_counter(visitor, number)
    @db.execute( "update matches set visit_count=? where name=?", number, visitor)
  end

  def get_visitor_count(visitor)
    result = @db.execute( "select visit_count from matches where name=?", visitor)
    result[0][0].to_i
  end

  def get_my_last_visit_date(user)
    result = @db.execute("select last_visit from matches where name=?", user)
    result[0][0].to_i
  end

  def set_my_last_visit_date(user)
    @db.execute( "update matches set last_visit=? where name=?", Time.now.to_i, user)
  end

  def set_visitor_timestamp(visitor, timestamp)
    @db.execute( "update matches set zindex=? where name=?", timestamp, visitor)
  end

  def get_visitor_timestamp(visitor)
    if self.existsCheck(visitor)
      result = @db.execute("select zindex from matches where name=?", visitor)
      result[0][0].to_i
    else
      @db.execute("insert into matches(name, count, zindex, ignore) values (?, 1, ?, ?)", visitor, Time.now.to_i, 'false')
      self.set_visitor_timestamp(visitor, Time.now.to_i)
    end
  end

  def log(match_name, match_percent=0)
    if existsCheck(match_name)
      count = self.get_visit_count(match_name) + 1
      self.update_visit_count(match_name, count)
      self.set_my_last_visit_date(match_name)
      # self.set_match_percentage(match_name, match_percent)
    else
      self.add_user(match_name)
    end
  end

  def add_user(username, count=1)
    if !(existsCheck(username))
      @db.execute( "insert into matches(name, count, ignore) values (?, ?, ?)", username, count, 'false')
    end
  end

  def delete_user(username)
    if existsCheck(username)
      @db.execute( "delete from matches where name=?", username)
    end
  end

  def is_ignored(username)
    result = @db.execute( "select ignore from matches where name=?", username)
    if result != true
      false
    else
      true
    end
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

# app = DatabaseManager.new(:login_name => "***REMOVED***")
# puts app.log("CyanideLady2")
# puts app.get_visit_count("CyanideLady2")
# app.delete_user("CyanideLady2")
# app.log("CyanideLady2")
# puts app.get_visit_count("CyanideLady2")
