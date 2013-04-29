class DatabaseManager

  def initialize(args)
    @login    = args[ :login_name]
    @settings = args[ :settings]
    open_db
    db_migrations
    @verbose  = @settings.verbose
    @debug    = @settings.debug
    @did_migrate = false
  end

  def db
    @db
  end

  def verbose
    @verbose
  end

  def db_migrations
    # Exceptional.rescue do
      # @db.execute("alter table matches add column account text")
      begin
      @db.execute("update matches set account=?", @login)
    rescue
      @db.execute("alter table matches add column account text")
      @db.execute("update matches set account=?", @login)

    end
    #   @db.execute("update matches set ignore_list=0 where ignored='false'")
    #   @db.execute("update matches set ignore_list=1 where ignored='true'")
    # end
    # @db.execute("alter table stats add column total_messages integer")
    # @db.execute("update stats set total_messages=0 where id=1")
    # @db.execute("delete from matches where gender=?", "Q")
  end

  def action(stmt)
    db.transaction
    stmt.execute
    db.commit
  end

  def open_db
    @db = SQLite3::Database.new( "./db/#{@login}.db" )
    import unless @did_migrate
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
        time_added text,
        smoking text,
        drinking text,
        kids text,
        drugs text,
        height text,
        body_type text,
        distance integer,
        match_percent integer,
        friend_percent integer,
        enemy_percent integer,
        last_msg_time integer,
        r_msg_count integer,
        last_online integer,
        ignore_list integer,
        PRIMARY KEY(name)
        )")
    rescue Exception => e
      # puts e.message
      puts e.message if verbose
      # Exceptional.handle(e, 'Database')
    end

    begin
      @db.execute("
        create table stats(
          total_visits integer,
          total_visitors integer,
          new_users integer,
          total_messages integer,
          id integer,
          PRIMARY KEY(id)
          )
        ")
      @db.execute("insert into stats(id, total_visitors, total_visits, new_users, total_messages) values (?, ?, ?, ?, ?)", 1, 0, 0, 0, 0)
    rescue Exception => e
      # Exceptional.handle(e, 'Database')
      puts e.message if verbose
    end
    db_migrations
    @did_migrate = true
  end

  def stats_add_visitors(number)
    updated = stats_get_visitor_count + number.to_i
    @db.execute("update stats set total_visitors=?", updated)
  end

  def stats_add_visit
    updated = stats_get_visits_count + 1
    @db.execute("update stats set total_visits=?", updated)
  end

  def stats_add_new_user
    updated = stats_get_new_users_count + 1
    @db.execute("update stats set new_users=?", updated)
  end

  def stats_add_new_messages(number)
    @db.execute("update stats set total_messages=? where id = 1", get_total_received_message_count)
  end

  def stats_get_visitor_count
    result = @db.execute("select total_visitors from stats where id = 1")
    result[0][0].to_i
  end

  def stats_get_visits_count
    result = @db.execute("select total_visits from stats where id = 1")
    result[0][0].to_i
  end

  def stats_get_new_users_count
    result = @db.execute("select new_users from stats where id = 1")
    result[0][0].to_i
  end

  def stats_get_total_messages
    result = @db.execute("select total_messages from stats where id = 1")
    result[0][0].to_i
  end

  def add_user(username, count=0)
    unless existsCheck(username) || username == "pictures"
      puts "Adding user:        #{username}" if verbose
      @db.transaction
      @db.execute( "insert into matches(name, counts, ignored, time_added) values (?, ?, ?, ?)", username, count, 'false', Time.now.to_i)
      @db.commit
      stats_add_new_user
    else
      puts "User already in db: #{username}" if verbose
    end
  end

  def delete_user(username)
      @db.execute("delete from matches where name=?", username)
  end

  def add_column(name, type)
    @db.execute("alter table matches add column ? ?", name, type)
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
    puts "Updating visit count: #{match_name}" if verbose
    @db.execute( "update matches set counts=? where name=?", number.to_i, match_name )
  end

  def rename_alist_user(old_name, new_name)
    # if existsCheck(new_name)
      # update_visit_count(new_name, get_visit_count(old_name) + get_visit_count(new_name) + 1)
    # else
      add_user(new_name)
      # update_visit_count(new_name, get_visit_count(old_name))
      # set_gender(:username => new_name, :gender => get_gender(old_name))
      # set_age(new_name, get_age(old_name))
      # set_city(new_name, get_city(old_name))
      # set_state(new_name, get_state(old_name))
      # set_visitor_counter(new_name, get_visitor_count(old_name))
      # set_visitor_timestamp(new_name, get_visitor_timestamp(old_name))
      # set_distance(new_name, get_distance(old_name))
      # set_match_percentage(new_name, get_match_percentage(old_name))
      # set_my_last_visit_date(new_name, get_my_last_visit_date(old_name))
      # set_received_messages_count(new_name, get_received_messages_count(old_name))
      # set_last_received_message_date(new_name, get_last_received_message_date(old_name))
    # end
    ignore_user(old_name)
    delete_user(old_name)
  end

  def no_gender(days)
    @db.execute( "select name from matches where gender is null and last_visit<?", days )
  end

  def new_user_smart_query
    @db.execute("select name from matches
    where (counts = 0 or counts is null)
    and (ignore_list=0 or ignore_list is null)
    and (gender is null or gender=?)
    order by last_online desc, time_added asc", @settings.gender)
  end

  def count_new_user_smart_query
    result = @db.execute("select count(name) as 'new_matches' from matches
    where (counts = 0 or counts is null)
    and (ignore_list=0 or ignore_list is null)
    and (gender is null or gender=?)
    order by time_added asc", @settings.gender)
    result[0][0].to_i
  end

  def followup_query

    min_time        = Chronic.parse("#{@settings.days_ago.to_i} days ago").to_i
    desired_gender  = @settings.gender
    min_age         = @settings.min_age
    max_age         = @settings.max_age
    min_counts      = 1
    max_counts      = @settings.max_followup
    min_percent     = @settings.min_percent

    case @settings.distance_filter_type
    when "state"
      location_filter     = "#{@settings.preferred_state}"
      preferred_state_alt = "#{location_filter} "
      result              = @db.execute("
        select name from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (state = ? or state = ? or state is null)
        and ignore_list is not 1
        and (age between ? and ? or age is null)
        and (match_percent between ? and 100 or match_percent is null or match_percent=0)
        and (gender is null or gender=?)",
                                        min_time.to_i,
                                        min_counts,
                                        max_counts,
                                        location_filter,
                                        preferred_state_alt,
                                        min_age,
                                        max_age,
                                        min_percent,
                                        desired_gender)
    when "distance"
      location_filter = @settings.max_distance
      result          = @db.execute("
        select name from matches
         where (last_visit <= ? or last_visit is null)
         and counts between ? and ?
         and (distance <= ? or distance is null)
         and ignore_list is not 1
         and (age between ? and ? or age is null)
         and (match_percent between ? and 100 or match_percent is null or match_percent=0)
         and (gender is null or gender=?)",
                                    min_time.to_i,
                                    min_counts,
                                    max_counts,
                                    location_filter,
                                    min_age,
                                    max_age,
                                    min_percent,
                                    desired_gender)
    when "city"
      location_filter     = "#{@settings.preferred_city}"
      preferred_city_alt  = "#{location_filter} "
      result              = @db.execute("
        select name from matches
          where (last_visit <= ? or last_visit is null)
          and counts between ? and ?
          and (city = ? or city = ? or city is null)
          and ignore_list is not 1
          and (age between ? and ? or age is null)
          and (match_percent between ? and 100 or match_percent is null or match_percent=0)
          and (gender is null or gender=?)
",
                                        min_time.to_i,
                                        min_counts,
                                        max_counts,
                                        location_filter,
                                        preferred_city_alt,
                                        min_age,
                                        max_age,
                                        min_percent,
                                        desired_gender)
    end
    result
  end

  def get_counts_of_follow_up

    min_time        = Chronic.parse("#{@settings.days_ago.to_i} days ago").to_i
    desired_gender  = @settings.gender
    min_age         = @settings.min_age
    max_age         = @settings.max_age
    min_counts      = 1
    max_counts      = @settings.max_followup
    min_percent     = @settings.min_percent

    case @settings.distance_filter_type
    when "state"
      location_filter     = "#{@settings.preferred_state}"
      preferred_state_alt = "#{@settings.preferred_state} "
      result              = @db.execute("
        select count(name) as 'follow_ups'
        from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (state = ? or state = ? or state is null)
        and ignore_list is not 1
        and (age between ? and ? or age is null)
        and (match_percent between ? and 100 or match_percent is null or match_percent=0)
        and (gender is null or gender=?)",
                                        min_time.to_i,
                                        min_counts,
                                        max_counts,
                                        location_filter,
                                        preferred_state_alt,
                                        min_age,
                                        max_age,
                                        min_percent,
                                        desired_gender)
    when "city"
      location_filter     = "#{@settings.preferred_city}"
      preferred_city_alt = "#{@settings.preferred_city} "
      result              = @db.execute("
        select count(name) as 'follow_ups'
        from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (city = ? or city = ? or city is null)
        and ignore_list is not 1
        and (age between ? and ? or age is null)
        and (match_percent between ? and 100 or match_percent is null or match_percent=0)
        and (gender is null or gender=?)",
                                        min_time.to_i,
                                        min_counts,
                                        max_counts,
                                        location_filter,
                                        preferred_city_alt,
                                        min_age,
                                        max_age,
                                        min_percent,
                                        desired_gender)
    when "distance"
      location_filter     = "#{@settings.max_distance}"
      result              = @db.execute("
        select count(name) as 'follow_ups'
        from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (distance <= ? or distance is null)
        and ignore_list is not 1
        and (age between ? and ? or age is null)
        and (match_percent between ? and 100 or match_percent is null or match_percent=0)
        and (gender is null or gender=?)",
                                        min_time.to_i,
                                        min_counts,
                                        max_counts,
                                        location_filter,
                                        min_age,
                                        max_age,
                                        min_percent,
                                        desired_gender)

    end
    # result.close
    result[0][0].to_i
  end

  def range_smart_query_by_state(
      min_time,
      min_counts,
      max_counts,
      preferred_state,
      min_age,
      max_age,
      min_percent,
    desired_gender=@settings.gender)
    preferred_state_alt = "#{preferred_state} "
    @db.execute("select name, visit_count from matches
        where (last_visit <= ? or last_visit is null)
        and counts between ? and ?
        and (state = ? or state = ? or state is null)
        and ignored is not 'true'
        and (age between ? and ? or age is null)
        and (match_percent between ? and 100 or match_percent is null or match_percent=0)
        and (gender is null or gender=?)", min_time, min_counts, max_counts, preferred_state, preferred_state_alt, min_age, max_age, min_percent, desired_gender)
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

  def set_friend_percentage(user, percent)
    @db.execute("update matches set friend_percent=? where name=?", percent, user)
  end

  def get_friend_percentage(user)
    @db.execute("select friend_percent from matches where name=?", user)
  end

  def set_enemy_percentage(user, percent)
    @db.execute("update matches set friend_percentage=? where name=?", percent, user)
  end

  def get_enemy_percentage(user)
    @db.execute("select enemy_percent from matches where name=?", user)
  end

  def set_slut_test_results(user, value)
    @db.execute("update matches set slut_test_results=? where name=?", value, user)
  end

  def get_slut_test_results(user)
    @db.execute("select slut_test_results from matches where name=?", user)
  end

  def set_ethnicity(user, value)
    @db.execute("update matches set ethnicity=? where name=?", value, user)
  end

  def get_ethnicity(user)
    @db.execute("select ethnicity from matches where name=?", user)
  end

  def set_height(user, value)
    @db.execute("update matches set height=? where name=?", value, user)
  end

  def get_height(user)
    @db.execute("select height from matches where name=?", user)
  end

  def set_body_type(user, value)
    @db.execute("update matches set body_type=? where name=?", value, user)
  end

  def get_body_type(user)
    @db.execute("select body_type from matches where name=?", user)
  end

  def set_smoking(user, value)
    @db.execute("update matches set smoking=? where name=?", value, user)
  end

  def get_smoking(user)
    @db.execute("select smoking from matches where name=?", user)
  end

  def set_drinking(user, value)
    @db.execute("update matches set drinking=? where name=?", value, user)
  end

  def get_drinking(user)
    @db.execute("select drinking from matches where name=?", user)
  end

  def set_drugs(user, value)
    @db.execute("update matches set drugs=? where name=?", value, user)
  end

  def get_drugs(user)
    @db.execute("select drugs from matches where name=?", user)
  end

  def set_kids(user, value)
    @db.execute("update matches set kids=? where name=?", value, user)
  end

  def get_kids(user)
    @db.execute("select kids from matches where name=?", user)
  end

  def set_last_online(user, date)
    @db.execute("update matches set last_online=? where name=?", date, user)
  end

  def get_last_online(user)
    result = @db.execute("select last_online from matches where name=?", user)
    result[0][0].to_i
  end

  def set_distance(args)
    user = args[ :username]
    dist = args[ :distance]
    @db.execute("update matches set distance=? where name=?", dist, user)
  end

  def get_distance(args)
    user = args[ :username]
    @db.execute("select distance from matches where name=?", user)
  end

  def set_state(args)
    user = args[ :username]
    state = args[ :state]
    @db.execute("update matches set state=? where name=?", state, user)
  end

  def get_state(user)
    result = @db.execute("select state from matches where name=?", user)
    result[0][0].to_s
  end

  def set_age(user, age)
    @db.execute("update matches set age=? where name=?", age.to_i, user)
  end

  def get_age(user)
    result = @db.execute("select age from matches where name=?", user)
    result[0][0].to_i
  end

  def set_time_added(args)
    user = args[ :username]
    @db.execute("update matches set time_added=? where name=?", Time.now.to_i, user)
  end

  def set_city(user, city)
    @db.execute("update matches set city=? where name=?", city, user)
  end

  def get_city(user)
    result = @db.execute("select city from matches where name=?", user)
    result[0][0].to_s
  end

  def set_gender(args)
    user = args[ :username]
    gender = args[ :gender]
    @db.execute("update matches set gender=? where name=?", gender, user)
  end

  def get_gender(user)
    @db.execute("select gender from matches where name=?", user)
  end

  def set_sexuality(user, sexuality)
    @db.execute("update matches set sexuality=? where name=?", sexuality, user)
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

  def set_received_messages_count(user, number)
    puts "Recieved msg count updated: #{user}" if verbose
    @db.execute("update matches set r_msg_count=? where name=?", number, user)
  end

  def get_received_messages_count(user)
    result = @db.execute("select r_msg_count from matches where name=?", user)
    result[0][0].to_i
  end

  def set_last_received_message_date(user, date)
    puts "Last Msg date updated: #{user}" if verbose
    @db.execute("update matches set last_msg_time=? where name=?", date, user)
  end

  def get_last_received_message_date(user)
    result = @db.execute("select last_msg_time from matches where name=?", user)
    begin
      result[0][0].to_i
    rescue
      puts result
    end
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
    puts "Updating last visit time: #{visitor}" if verbose
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

  def get_total_received_message_count
    result = @db.execute("select count(name) as 'senders' from matches where r_msg_count is not null")
    result[0][0].to_i
  end

  def get_all_message_senders
    @db.execute("select name, city, state from matches where r_msg_count is not null")
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
      add_user(match_name)
      # set_sexuality(match_name, sexuality)
      # set_gender(:username => match_name, :gender => gender)
    end
  end

  def log2(user)
    if user.handle
      unless existsCheck(user.handle)
        add_user(user.handle)
      end
      count = get_visit_count(user.handle) + 1
      update_visit_count(user.handle, count)
      set_my_last_visit_date(user.handle)
      set_gender(:username => user.handle.to_s, :gender => user.gender.to_s)
      set_sexuality(user.handle, user.sexuality)
      set_match_percentage(user.handle, user.match_percentage)
      set_state(:username => user.handle, :state => user.state)
      set_distance(:username => user.handle, :distance => user.relative_distance)
      set_age(user.handle, user.age)
      set_city(user.handle, user.city)
      set_smoking(user.handle, user.smoking)
      set_body_type(user.handle, user.body_type)
      set_drugs(user.handle, user.drugs)
      set_drinking(user.handle, user.drinking)
      set_height(user.handle, user.height)
      set_last_online(user.handle, user.last_online)
    end
    stats_add_visit
  end

  def reset_ignored_list
    @db.execute("update matches set ignored='false' where ignored='true'")
    @db.execute("update matches set ignored='true' where gender='M'")
  end

  def is_ignored(username)
    add_user(username) unless existsCheck(username)
    result = @db.execute( "select ignore_list from matches where name=?", username)
    # to_boolean(result[0][0].to_s)
    # begin
    result[0][0].to_i == 1
    # rescue
    # false
    # end
  end

  def send_command(command)
    @db.execute( "?", command)
  end

  def ignore_user(username)
    unless existsCheck(username)
      add_user(username)
    end
    unless is_ignored(username)
      puts "Added to ignore list: #{username}" if verbose
      @db.execute( "update matches set ignore_list=1 where name=?", username)
    else
      puts "User already ignored: #{username}" if verbose
    end
  end

  def unignore_user(username)
    @db.execute( "update matches set ignore_list=0 where name=?", username)
  end

  def existsCheck(username)
    @db.execute( "select 1 where exists(
          select 1
          from matches
          where name = ?
      ) ", username).any?
  end

  def remove_unknown_gender
    @db.execute("delete from matches where gender=?", "Q")
  end

  def to_boolean(str)
    str == 'true'
  end

  def close
    # @db.commit
    # @db.close
    puts "you missed one."
  end

  def exit_db
    @db.close
  end


  def commit
    @db.commit
  end

end
