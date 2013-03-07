class DatabaseManager

  def initialize(args)
    @login = args[ :login_name]
    open_db
  end

  def db
    @db
  end

  def action(stmt)
    db.transaction
    stmt.execute
    db.commit
  end

  def open_db
    @db = SQLite3::Database.new( "./db/#{@login}.db" )
    # import
  end

  def open
    open_db
  end

  def import
    begin
      @db.execute("CREATE TABLE matches(
        name text,
        counts integer,
        ignored text,
        zindex integer,
        visit_count integer,
        last_visit integer,
        gender text,
        sexuality text,
        age integer,
        relationship_status text,
        match_percentage integer,
        state text,
        city text,
        PRIMARY KEY(name)
        )")
    rescue Exception => e
      puts e.message
    end
    # CSV.foreach("#{@login}_count.csv", :headers => false, :skip_blanks => false) do |row|
    #   @db.execute( "insert into matches
    #         (name, count, ignore, zindex, visit_count, last_visit)
    #         values (?, ?, ?, ?, ?, ?)",
    #                row[0], row[1], row[2], row[3], row[4], row[5])
    # end

  end

  def add_user(args)
    username = args[ :username]
    count = 0
    unless existsCheck(username)
      @db.transaction
      @db.execute( "insert into matches(name, counts, ignored) values (?, ?, ?)", username, count, 'false')
      set_time_added(:username => username)
      @db.commit
    end
  end

  def delete_user(username)
    if existsCheck(username)
      @db.transaction
      @db.execute( "delete from matches where name=?", username)
      @db.commit
    end
  end

  def add_column(name, type)
    @db.execute("alter table matches add column ? ?", name, type)
  end

  def delete_men
    results = @db.execute("delete from matches where gender=?", "M")
  end

  def get_match_names
    @db.execute( "select name from matches" )
  end

  def get_visit_count(user)
    row = @db.execute( "select counts from matches where name= ? ", user)
    begin
      row[0][0].to_i
    rescue
      0
    end
  end

  # def get_last_visit_date(user)
  #   result = @db.execute( "select last_visit from matches where name=?", user)
  #   result[0][0].to_i
  # end

  def update_visit_count(match_name, number)
    @db.execute( "update matches set counts=? where name=?", number.to_i, match_name )
  end

  def filter_by_visits(max, min=0)
    @db.execute( "select name from matches where counts between ? and ?", min, max )
  end

  def filter_by_dates(min=0, max)
    @db.execute( "select name from matches where last_visit between ? and ?", min, max)
  end

  def no_gender(days)
    @db.execute( "select name from matches where gender is null and last_visit<?", days )
  end

  def better_smart_query(min_time, max_counts, desired_gender="F")
    puts min_time
    sleep 2
    @db.execute("select name from matches
      where (last_visit <= ? or last_visit is null)
      and counts=?
      and (gender is null or gender=?)", min_time, max_counts, desired_gender)
  end

  def new_user_smart_query
    @db.execute("select name, counts, state from matches
    where (counts=0 or counts is null)
    and (ignored is 'false' or ignored is null)
    and (gender is null or gender=?)", "F")

  end


  def better_smart_query2(desired_gender="F")
    @db.execute("select name from matches
      where last_visit is null
      and counts is null
      and (ignored='false' or ignored is null)
      and (gender is null or gender=?)", desired_gender)
  end

  def range_smart_query(min_time, min_counts, max_counts, desired_gender="F")
    @db.execute("select name, visit_count from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (match_percent between ? and 100 or match_percent is null)
        and (gender is null or gender=?)
        order by visit_count desc", min_time, min_counts, max_counts, 60, desired_gender)
  end

  def user_record_exists(user)
    @db.execute( "select exists(select * from matches where name=?", user )
  end

  def set_match_percentage(user, match_percentage)
    # begin
    @db.execute("update matches set match_percent=? where name=?", match_percentage, user)
    # rescue
    #   @db.execute("alter table matches add column match_percent text")
    #   @db.execute("update matches set match_percent=? where name=?", match_percentage, user)
    # end

  end

  def set_distance(args)
    user = args[ :username]
    dist = args[ :distance]
    begin
      @db.execute("update matches set distance=? where name=?", dist, user)
    rescue
      @db.execute("alter table matches add column distance integer")
      @db.execute("update matches set distance=? where name=?", dist, user)
    end
  end

  def get_distance(args)
    user = args[ :username]
    begin
      @db.execute("select distance from matches where name=?", user)
    rescue
      @db.execute("alter table matches add column distance integer")
      nil
    end
  end

  def set_state(args)
    user = args[ :username]
    state = args[ :state]
    begin
      @db.execute("update matches set state=? where name=?", state, user)
    rescue
      @db.execute("alter table matches add column state text")
      @db.execute("update matches set state=? where name=?", state, user)
    end
  end

  def set_time_added(args)
    user = args[ :username]
    begin
      @db.execute("update matches set time_added=? where name=?", Time.now.to_i, user)
    rescue
      @db.execute("alter table matches add column time_added integer")
      @db.execute("update matches set time_added=? where name=?", Time.now.to_i, user)
    end
  end

  def set_gender(args)
    user = args[ :username]
    gender = args[ :gender]
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
    begin
      result[0][0].to_i
    rescue
      0
    end
  end

  def get_my_last_visit_date(user)
    result = @db.execute("select last_visit from matches where name=?", user)
    begin
      result[0][0].to_i
    rescue
      0
    end
  end

  def set_my_last_visit_date(user)
    @db.execute( "update matches set last_visit=? where name=?", Time.now.to_i, user)
  end

  def set_visitor_timestamp(visitor, timestamp)
    @db.execute( "update matches set zindex=? where name=?", timestamp, visitor)
  end

  def get_visitor_timestamp(visitor)
    if existsCheck(visitor)
      result = @db.execute("select zindex from matches where name=?", visitor)
      result[0][0].to_i
    else
      @db.execute("insert into matches(name, counts, zindex, ignored) values (?, 1, ?, ?)", visitor, Time.now.to_i, 'false')
      set_visitor_timestamp(visitor, Time.now.to_i)
      Time.now.to_i
    end
  end

  def log(match_name, match_percent=0)
    if existsCheck(match_name)
      count = get_visit_count(match_name) + 1
      update_visit_count(match_name, count)
      set_my_last_visit_date(match_name)
      # set_gender(:username => match_name, :gender => gender)
      # set_sexuality(match_name, sexuality)
      # set_match_percentage(match_name, match_percent)
    else
      add_user(:username => match_name)
      # set_sexuality(match_name, sexuality)
      # set_gender(:username => match_name, :gender => gender)
    end
  end

  def log2(user)
    if user.handle
      unless existsCheck(user.handle)
        add_user(:username => user.handle)
      end
      count = get_visit_count(user.handle) + 1
      update_visit_count(user.handle, count)
      set_my_last_visit_date(user.handle)
      set_gender(:username => user.handle.to_s, :gender => user.gender.to_s)
      set_sexuality(user.handle, user.sexuality)
      set_match_percentage(user.handle, user.match_percentage)
      set_state(:username => user.handle, :state => user.state)
      set_distance(:username => user.handle, :distance => user.relative_distance)
    end
  end


  def is_ignored(username)
    result = @db.execute( "select ignored from matches where name=?", username)
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
    @db.execute( "update matches set ignored='true' where name=?", username)
  end

  def unignore_user(username)
    @db.execute( "update matches set ignored='false' where name=?", username)
  end

  def existsCheck( id )
    # begin
    temp = @db.execute( "select 1 where exists(
          select 1
          from matches
          where name = ?
      ) ", [id] ).any?
    # rescue
    # import
    # end
  end

  def to_boolean(str)
    str == 'true'
  end

  def close
    # @db.commit
    @db.close
  end

  def commit
    @db.commit
  end

end
