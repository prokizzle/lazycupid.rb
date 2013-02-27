class DatabaseManager

  def initialize(args)
    login = args[ :login_name]
    open_db(login)


  end

  def open_db( db )
    # begin
    @db = SQLite3::Database.new( "./db/#{db}.db" )
    # rescue
    # end

  end

  def import
    begin
      @db.execute("CREATE TABLE matches(
        name text,
        count integer,
        ignore text,
        zindex integer,
        visit_count integer,
        last_visit integer,
        gender text,
        sexuality text,
        age integer,
        relationship_status text,
        match_percentage integer,
        PRIMARY KEY(name)
        )"
                  )
    rescue
    end
    # CSV.foreach("#{@login}_count.csv", :headers => false, :skip_blanks => false) do |row|
    #   @db.execute( "insert into matches
    #         (name, count, ignore, zindex, visit_count, last_visit)
    #         values (?, ?, ?, ?, ?, ?)",
    #                row[0], row[1], row[2], row[3], row[4], row[5])
    # end

  end

  def add_column(name, type)
    @db.execute("alter table matches add column ? ?", name, type)
  end

  def delete_men
    results = @db.execute("select name from matches where gender=?", "M")
    results.each do |user|
      puts "Deleting #{user}"
      self.delete_user(user)
    end
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

  def no_gender(days)
    @db.execute( "select name from matches where gender is null and last_visit<?", days )
  end

  def better_smart_query(min_time, max_counts, desired_gender="F")
    @db.execute("select name from matches
      where (last_visit <= ? or last_visit is null)
      and count=?
      and (gender is null or gender=?)", min_time, max_counts, desired_gender)
  end

  def better_smart_query2(desired_gender="F")
    @db.execute("select name from matches
      where last_visit is null
      and count is null
      and (ignore='false' or ignore is null)
      and (gender is null or gender=?)", desired_gender)
  end

  def range_smart_query(min_time, min_counts, max_counts, desired_gender="F")
      @db.execute("select name from matches
        where (last_visit <= ? or last_visit is null)
        and count between ? and ?
        and (gender is null or gender=?)", min_time, min_counts, max_counts, desired_gender)
  end

  def user_record_exists(user)
    @db.execute( "select exists(select * from matches where name=" + user )
  end

  def set_match_percentage(user, match_percent)
    begin
      @db.execute("update matches set match_percent=? where name=?", user, match_percent)
    rescue
      @db.execute("alter table matches add column match_percent text")
      @db.execute("update matches set match_percent=? where name=?", user, match_percent)
    end

  end

  def set_gender(user, gender)
    begin
      @db.execute("update matches set gender=? where name=?", gender, user)
    rescue
      @db.execute("alter table matches add column gender text")
      @db.execute("update matches set gender=? where name=?", gender, user)
    end
  end

  def get_gender(user)
    @db.execute("select gender from matches where name=?", user)
  end

  def set_sexuality(user, sexuality)
    begin
      @db.execute("update matches set sexuality=? where name=?", sexuality, user)
    rescue
      @db.execute("alter table matches add column sexuality text")
      @db.execute("update matches set sexuality=? where name=?", sexuality, user)
    end
  end

  def get_sexuality(user)
    @db.execute("select sexuality from matches where name=?", user)
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
      Time.now.to_i
    end
  end

  def log(match_name, match_percent=0)
    if existsCheck(match_name)
      count = self.get_visit_count(match_name) + 1
      self.update_visit_count(match_name, count)
      self.set_my_last_visit_date(match_name)
      # self.set_gender(match_name, gender)
      # self.set_sexuality(match_name, sexuality)
      # self.set_match_percentage(match_name, match_percent)
    else
      self.add_user(match_name)
      # self.set_sexuality(match_name, sexuality)
      # self.set_gender(match_name, gender)
    end
  end

  def log2(user)
    if existsCheck(user.handle)
      count = self.get_visit_count(user.handle) + 1
      self.update_visit_count(user.handle, count)
      self.set_my_last_visit_date(user.handle)
      self.set_gender(user.handle.to_s, user.gender.to_s)
      self.set_sexuality(user.handle, user.sexuality)
      self.set_match_percentage(user.handle, user.match_percentage)
    else
      self.add_user(user.handle)
      self.set_sexuality(user.handle, user.sexuality)
      self.set_gender(user.handle, user.gender)
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
    # to_boolean(result[0][0].to_s)
    begin
      (result[0][0].to_s == "true")
    rescue
      false
    end
  end

  def send_command(command)
    @db.execute( "?", command)
  end

  def ignore_user(username)
    @db.execute( "update matches set ignore='true' where name=?", username)
  end

  def unignore_user(username)
    @db.execute( "update matches set ignore='false' where name=?", username)
  end

  def existsCheck( id )
    begin
    temp = @db.execute( "select 1 where exists(
          select 1
          from matches
          where name = ?
      ) ", [id] ).any?
    rescue
    self.import
    end
  end

  def to_boolean(str)
    str == 'true'
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