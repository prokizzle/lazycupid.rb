class DatabaseMgr
  attr_reader :login, :debug, :verbose


  def initialize(args)
    @did_migrate = false
    @login    = args[ :login_name]
    @settings = args[ :settings]
    @db = PGconn.connect( :dbname => @settings.db_name,
                          :password => @settings.db_pass,
                          :user => @settings.db_user
                          )
    open_db
    db_tasks
    @verbose  = @settings.verbose
    @debug    = @settings.debug
    # delete_self_refs
  end

  def db
    @db
  end

  def verbose
    @verbose
  end

  def delete_self_refs
    @db.exec("delete from matches where name = $1", [@login])
    @db.exec("delete from matches where name = $1", [nil])
    @db.exec("delete from matches where name = $1", [""])
  end

  def db_tasks
    puts "Executing db tasks..."
    @db.exec("alter table matches add column prev_visit integer")
  end

  def action(stmt)
    db.transaction
    stmt.execute
    db.commit
  end

  def open_db
    import unless @did_migrate
  end

  def open
    open_db
  end

  def import
    begin
      @db.exec("CREATE TABLE matches(
        name text,
        account text,
        counts integer,
        ignored text,
        visitor_timestamp integer,
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
        ignore_list integer        )")
    rescue Exception => e
      puts e.message if verbose
    end

    begin
      @db.exec("
        create table stats(
          total_visits integer,
          total_visitors integer,
          new_users integer,
          total_messages integer,
          account text
          )
        ")
      @db.exec("insert into stats(total_visitors, total_visits, new_users, total_messages, account) values ($1, $2, $3, $4, $5)", [0, 0, 0, 0, @login])
    rescue Exception => e
      puts e.message if verbose
    end
    @did_migrate = true
  end

  def stats_add_visit
    @db.exec("update stats set total_visits=total_visits + 1 where account=$1", [@login])
  end

  def stats_add_visitor
    @db.exec("update stats set total_visitors=total_visitors+1 where account=$1", [@login])
  end

  def stats_add_new_user
    # updated = stats_get_new_users_count + 1
    @db.exec("update stats set new_users=new_users + 1 where account=$1", [@login])
  end

  def stats_add_new_message
    @db.exec("update stats set total_messages=total_messages + 1 where account=$1", [@login])
  end

  def stats_get_visitor_count
    result = @db.exec("select total_visitors from stats where account=$1", [@login])
    result[0]["total_visitors"].to_i
  end

  def stats_get_visits_count
    result = @db.exec("select total_visits from stats where account=$1", [@login])
    result[0]["total_visits"].to_i
  end

  def stats_get_new_users_count
    result = @db.exec("select new_users from stats where account=$1", [@login])
    result[0]["new_users"].to_i
  end

  def stats_get_total_messages
    result = @db.exec("select total_messages from stats where account=$1", [@login])
    result[0]["total_messages"].to_i
  end

  def add_user(username, gender, added_from)
    unless existsCheck(username) || username == "pictures"
      puts "Adding user:        #{username}" if verbose
      # @db.transaction
      @db.exec("insert into matches(name, ignore_list, time_added, account, counts, gender, added_from) values ($1, $2, $3, $4, $5, $6, $7)", [username.to_s, 0, Time.now.to_i, @login.to_s, 0, gender, added_from])
      # @db.commit
      stats_add_new_user
    else
      puts "User already in db: #{username}" if verbose
    end
  end

  def delete_user(username)
    @db.exec("delete from matches where name=$1 and account=$2", [username, @login])
  end

  def get_match_names
    @db.exec( "select name from matches where account=$1", [@login] )
  end

  def get_visit_count(user)
    row = @db.exec( "select counts from matches where name=$1 and account=$2", [user, @login])
    begin
      row[0]["counts"].to_i
    rescue
      0
    end
  end

  def set_visit_count(name, count)
    @db.exec("update matches set counts = $1 where name=$2 and account = $3", [count, name, @login])
  end

  # def get_last_visit_date(user)
  #   result = @db.exec( "select last_visit from matches where name=$1 and account=$2", [user, @login])
  #   result[0]["last_visit"].to_i
  # end

  def update_visit_count(match_name, number)
    puts "Updating visit count: #{match_name}" if verbose
    @db.exec( "update matches set counts=$1 where name=$2 and account=$3", [number.to_i, match_name, @login] )
  end

  def increment_visit_count(match_name)
    puts "Incrementing visit count: #{match_name}" if verbose
    @db.exec("update matches set counts=counts + 1 where name=$1 and account=$2", [match_name, @login])
  end

  def rename_alist_user(old_name, new_name)
    # if existsCheck(new_name)
    # update_visit_count(new_name, get_visit_count(old_name) + get_visit_count(new_name) + 1)
    # else
    add_user(new_name, get_gender(old_name), "a_list_rename")
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
    @db.exec( "select name from matches where gender is null and last_visit<$1 and account=$2", [days, @login] )
  end

  def toggle_flag(name)
    @db.exec("update matches set flag=flag * -1 where name=$1 and account=$2", [name, @login])
  end

  def new_user_smart_query
    @db.exec("select name from matches
    where account=$2
    and counts = 0
    and (ignore_list=0 or ignore_list is null)
    and (gender=$1)
    order by last_online desc, time_added asc", [@settings.gender, @login])

  end

  def focus_query_new_users
    desired_gender      = @settings.gender
    min_age             = @settings.min_age
    max_age             = @settings.max_age
    max_distance        = @settings.max_distance
    age_sort            = @settings.age_sort
    height_sort         = @settings.height_sort
    last_online_cutoff  = @settings.last_online_cutoff
    min_counts          = 1
    max_counts          = @settings.max_followup
    min_percent         = @settings.min_percent
    time = Time.now.to_i
    date_range_min = time - 1209600
    date_range_max = time - 604800
    @db.exec("select name from matches
      where account=$1
      and (last_visit >= $2 or last_visit is null)
      and time_added between $3 and $4
      and ignore_list=0
      and age between $6 and $7
      and distance <= $8
      and gender=$5",
      [@login, #1
      time - 86400, #2
      date_range_min, #3
      date_range_max, #4
      @settings.gender, #5
      min_age, #6
      max_age, #7
      max_distance #8
      ])
  end

  def count_new_user_smart_query
    result = @db.exec("select count(name) from matches
    where account=$2
    (counts = 0 or counts is null)
    and (ignore_list=0 or ignore_list is null)
    and (gender=$1)
    order by time_added asc", [@settings.gender, @login])
    result[0][0].to_i
  end

  def followup_query

    min_time            = Chronic.parse("#{@settings.days_ago.to_i} days ago").to_i
    desired_gender      = @settings.gender
    min_age             = @settings.min_age
    max_age             = @settings.max_age
    age_sort            = @settings.age_sort
    height_sort         = @settings.height_sort
    last_online_cutoff  = @settings.last_online_cutoff
    min_counts          = 1
    max_counts          = @settings.max_followup
    min_percent         = @settings.min_percent

    case @settings.distance_filter_type
    when "state"
      location_filter     = "#{@settings.preferred_state}"
      preferred_state_alt = "#{location_filter} "
      result              = @db.exec("
        select name from matches
        where account=$10
        and(last_visit <= $1 or last_visit is null)
        and counts between $2 and $3
        and (state = $4 or state = $5 or state is null)
        and ignore_list = 0
        and (age between $6 and $7 or age is null)
        and (match_percent between $8 and 100 or match_percent is null or match_percent=0)
        and (gender=$9)
        and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')))
        order by counts ASC, last_online DESC, match_percent DESC, distance ASC, height #{height_sort}, age #{age_sort}",
                                     [min_time.to_i,
                                      min_counts,
                                      max_counts,
                                      location_filter,
                                      preferred_state_alt,
                                      min_age,
                                      max_age,
                                      min_percent,
                                      desired_gender,
                                      @login])

    when "distance"
      location_filter = @settings.max_distance
      result          = @db.exec("
        select name from matches
         where account=$9
        and (last_visit <= $1 or last_visit is null)
         and counts between $2 and $3
         and (distance <= $4 or distance is null)
         and ignore_list = 0
         and (age between $5 and $6 or age is null)
         and (match_percent between $7 and 100 or match_percent is null or match_percent=0)
         and (gender=$8)
         and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')))
         order by counts ASC, last_online DESC, match_percent DESC, distance ASC, height #{height_sort}, age #{age_sort}",
                                 [min_time.to_i,
                                  min_counts,
                                  max_counts,
                                  location_filter,
                                  min_age,
                                  max_age,
                                  min_percent,
                                  desired_gender,
                                  @login])
    when "city"
      location_filter     = "#{@settings.preferred_city}"
      preferred_city_alt  = "#{location_filter} "
      result              = @db.exec("
        select name from matches
          where account=$10
          and (last_visit <= $1 or last_visit is null)
          and counts between $2 and $3
          and (city = $4 or city = $5 or city is null)
          and ignore_list = 0
          and (age between $6 and $7 or age is null)
          and (match_percent between $8 and 100 or match_percent is null or match_percent=0)
          and (gender=$9)
          and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')))
          order by counts ASC, last_online DESC, match_percent DESC, distance ASC, height #{height_sort}, age #{age_sort}",
                                     [min_time.to_i,
                                      min_counts,
                                      max_counts,
                                      location_filter,
                                      preferred_city_alt,
                                      min_age,
                                      max_age,
                                      min_percent,
                                      desired_gender,
                                      @login])
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
      result              = @db.exec("
        select count(name)
        from matches
        where account=$1
        and (last_visit <= $2 or last_visit is null)
        and counts between $3 and $4
        and (state = $5 or state = $6 or state is null)
        and ignore_list = 0
        and (age between $7 and $8 or age is null)
        and (match_percent between $9 and 100 or match_percent is null or match_percent=0)
        and (gender=$10)",
                                     [@login,
                                      min_time.to_i,
                                      min_counts,
                                      max_counts,
                                      location_filter,
                                      preferred_state_alt,
                                      min_age,
                                      max_age,
                                      min_percent,
                                      desired_gender])
    when "city"
      location_filter     = "#{@settings.preferred_city}"
      preferred_city_alt = "#{@settings.preferred_city} "
      result              = @db.exec("
        select count(name)
        from matches
        where account=$1
        and (last_visit <= $2 or last_visit is null)
        and counts between $3 and $4
        and (city = $5 or city = $6 or city is null)
        and ignore_list = 0
        and (age between $7 and $8 or age is null)
        and (match_percent between $9 and 100 or match_percent is null or match_percent=0)
        and (gender=$10)",
                                     [@login,
                                      min_time.to_i,
                                      min_counts,
                                      max_counts,
                                      location_filter,
                                      preferred_city_alt,
                                      min_age,
                                      max_age,
                                      min_percent,
                                      desired_gender])
    when "distance"
      location_filter     = "#{@settings.max_distance}"
      result              = @db.exec("
        select count(name)
        from matches
        where account=$1
        and (last_visit <= $2 or last_visit is null)
        and counts between $3 and $4
        and (distance <= $5 or distance is null)
        and ignore_list = 0
        and (age between $6 and $7 or age is null)
        and (match_percent between $8 and 100 or match_percent is null or match_percent=0)
        and (gender=$9)",
                                     [@login,
                                      min_time.to_i,
                                      min_counts,
                                      max_counts,
                                      location_filter,
                                      min_age,
                                      max_age,
                                      min_percent,
                                      desired_gender])

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
    @db.exec("select name, visit_count from matches
        where account=$1
        and (last_visit <= $2 or last_visit is null)
        and counts between $3 and $4
        and (state = $5 or state = $6 or state is null)
        and ignored is not 'true'
        and (age between $7 and $8 or age is null)
        and (match_percent between $9 and 100 or match_percent is null or match_percent=0)
        and (gender=$10)", [@login, min_time, min_counts, max_counts, preferred_state, preferred_state_alt, min_age, max_age, min_percent, desired_gender])
  end

  def user_record_exists(user)
    @db.exec( "select exists(select * from matches where name=$1 and account=$2", [user, @login] )
  end

  def set_match_percentage(user, match_percentage)
    # begin
    @db.exec("update matches set match_percent=$1 where name=$2 and account=$3", [match_percentage, user, @login])
    # rescue
    #   @db.exec("alter table matches add column match_percent text")
    #   @db.exec("update matches set match_percent=$1 where name=$2", [match_percentage, user])
    # end

  end

  def set_friend_percentage(user, percent)
    @db.exec("update matches set friend_percent=$1 where name=$2 and account=$3", [percent, user, @login])
  end

  def get_friend_percentage(user)
    @db.exec("select friend_percent from matches where name=$1 and account=$2", [user, @login])
  end

  def test_this
    @db.exec("select new_users from stats where account=$1", [@login])
  end

  def set_enemy_percentage(user, percent)
    @db.exec("update matches set friend_percentage=$1 where name=$2 and account=$3", [percent, user, @login])
  end

  def get_enemy_percentage(user)
    @db.exec("select enemy_percent from matches where name=$1 and account=$2", [user, @login])
  end

  def set_slut_test_results(user, value)
    @db.exec("update matches set slut_test_results=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_slut_test_results(user)
    @db.exec("select slut_test_results from matches where name=$1 and account=$2", [user, @login])
  end

  def set_ethnicity(user, value)
    @db.exec("update matches set ethnicity=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_ethnicity(user)
    @db.exec("select ethnicity from matches where name=$1 and account=$2", [user, @login])
  end

  def set_height(user, value)
    @db.exec("update matches set height=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_height(user)
    @db.exec("select height from matches where name=$1 and account=$2", [user, @login])
  end

  def set_body_type(user, value)
    @db.exec("update matches set body_type=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_body_type(user)
    @db.exec("select body_type from matches where name=$1 and account=$2", [user, @login])
  end

  def set_smoking(user, value)
    @db.exec("update matches set smoking=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_smoking(user)
    @db.exec("select smoking from matches where name=$1 and account=$2", [user, @login])
  end

  def set_drinking(user, value)
    @db.exec("update matches set drinking=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_drinking(user)
    @db.exec("select drinking from matches where name=$1 and account=$2", [user, @login])
  end

  def set_drugs(user, value)
    @db.exec("update matches set drugs=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_drugs(user)
    @db.exec("select drugs from matches where name=$1 and account=$3", [user, @login])
  end

  def set_kids(user, value)
    @db.exec("update matches set kids=$1 where name=$2 and account=$3", [value, user, @login])
  end

  def get_kids(user)
    @db.exec("select kids from matches where name=$1 and account=$2", [user, @login])
  end

  def set_last_online(user, date)
    @db.exec("update matches set last_online=$1 where name=$2 and account=$3", [date, user, @login])
  end

  def get_last_online(user)
    result = @db.exec("select last_online from matches where name=$1 and account=$2", [user, @login])
    result[0]["last_online"].to_i
  end

  def set_distance(args)
    user = args[ :username]
    dist = args[ :distance]
    @db.exec("update matches set distance=$1 where name=$2 and account=$3", [dist, user, @login])
  end

  def get_distance(args)
    user = args[ :username]
    @db.exec("select distance from matches where name=$1 and account=$2", [user, @login])
  end

  def set_state(args)
    user = args[ :username]
    state = args[ :state]
    @db.exec("update matches set state=$1 where name=$2 and account=$3", [state, user, @login])
  end

  def get_state(user)
    result = @db.exec("select state from matches where name=$1 and account=$2", [user, @login])
    result[0]["state"].to_s
  end

  def set_age(user, age)
    @db.exec("update matches set age=$1 where name=$2 and account=$3", [age.to_i, user, @login])
  end

  def get_age(user)
    result = @db.exec("select age from matches where name=$1 and account=$2", [user, @login])
    result[0]["age"].to_i
  end

  def set_time_added(args)
    user = args[ :username]
    @db.exec("update matches set time_added=$1 where name=$2 and account=$3", [Time.now.to_i, user, @login])
  end

  def set_city(user, city)
    @db.exec("update matches set city=$1 where name=$2 and account=$3", [city, user, @login])
  end

  def get_city(user)
    result = @db.exec("select city from matches where name=$1 and account=$2", [user, @login])
    result[0]["city"].to_s
  end

  def set_gender(args)
    user = args[ :username]
    gender = args[ :gender]
    @db.exec("update matches set gender=$1 where name=$2 and account=$3", [gender, user, @login])
  end

  def get_gender(user)
    @db.exec("select gender from matches where name=$1 and account=$2", [user, @login])
  end

  def set_sexuality(user, sexuality)
    @db.exec("update matches set sexuality=$1 where name=$2 and account=$3", [sexuality, user, @login])
  end

  def get_sexuality(user)
    @db.exec("select sexuality from matches where name=$1 and account=$2", [user, @login])
  end

  def get_match_percentage(user)
    result = @db.exec("select match_percent from matches where name=$1 and account=$2", [user, @login])
    result[0]["match_percent"].to_i
  end

  def increment_visitor_counter(visitor)
    @db.exec( "update matches set visit_count=visit_count+1 where name=$1 and account=$2", [visitor, @login])
  end

  def increment_received_messages_count(user)
    puts "Recieved msg count updated: #{user}" if verbose
    @db.exec("update matches set r_msg_count=r_msg_count+1 where name=$1 and account=$2", [user, @login])
  end

  def get_received_messages_count(user)
    result = @db.exec("select r_msg_count from matches where name=$1 and account=$2", [user, @login])
    result[0]["r_msg_count"].to_i
  end

  def set_last_received_message_date(user, date)
    puts "Last Msg date updated: #{user}" if verbose
    @db.exec("update matches set last_msg_time=$1 where name=$2 and account=$3", [date, user, @login])
  end

  def get_last_received_message_date(user)
    result = @db.exec("select last_msg_time from matches where name=$1 and account=$2", [user, @login])
    begin
      result[0]["last_msg_time"].to_i
    rescue
      puts result
    end
  end

  def get_visitor_count(visitor)
    result = @db.exec( "select visit_count from matches where name=$1 and account=$2", [visitor, @login])
    begin
      result[0]["visit_count"].to_i
    rescue
      0
    end
  end

  def get_my_last_visit_date(user)
    result = @db.exec("select last_visit from matches where name=$1 and account=$2", [user, @login])
    begin
      result[0]["last_visit"].to_i
    rescue
      0
    end
  end

  def set_my_last_visit_date(user, date=Time.now.to_i)
    @db.exec("update matches set prev_visit=$1 where name=$2 and account=$3", [get_my_last_visit_date(user), user, @login])
    @db.exec( "update matches set last_visit=$1 where name=$2 and account=$3", [date, user, @login])
  end

  def set_visitor_timestamp(visitor, timestamp)
    puts "Updating last visit time: #{visitor}" if verbose
    @db.exec( "update matches set visitor_timestamp=$1 where name=$2 and account=$3", [timestamp, visitor, @login])
  end

  def get_visitor_timestamp(visitor)
    if existsCheck(visitor)
      result = @db.exec("select visitor_timestamp from matches where name=$1 and account=$2", [visitor, @login])
      result[0]["visitor_timestamp"].to_i
    else
      @db.exec("insert into matches(name, counts, visitor_timestamp, ignored, account) values ($1, $2, $3, $4, $5)", [visitor, 1, Time.now.to_i, 'false', @login])
      set_visitor_timestamp(visitor, Time.now.to_i)
      Time.now.to_i
    end
  end

  def get_total_received_message_count
    result = @db.exec("select count(name) from matches where r_msg_count is not null and account=$1", [@login])
    result[0][0].to_i
  end

  def get_all_message_senders
    @db.exec("select name, city, state from matches where r_msg_count is not null and account=$1", [@login])
  end

  def log2(user)
    if user[:handle]
      unless existsCheck(user[:handle])
        add_user(user[:handle])
      end

      increment_visit_count(user[:handle])
      set_my_last_visit_date(user[:handle])
      set_user_details(user)
      p "Height: #{user[:height]}"
    end
    stats_add_visit
  end

  def set_user_details(user)
    @db.exec("update matches
      set (gender, sexuality, match_percentage, state, distance, age, city, height, last_online) =
      ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      where name=$10",
             [user[:gender],
              user[:sexuality],
              user[:match_percentage],
              user[:state],
              user[:distance],
              user[:age],
              user[:city],
              user[:height],
              user[:last_online],
              user[:handle]])
  end

  def reset_ignored_list
    @db.exec("update matches set ignored='false' where ignored='true' and account=$1", [@login])
    @db.exec("update matches set ignored='true' where gender='M' and account=$1", [@login])
  end

  def is_ignored(username, gender="Q")
    array = Array.new
    add_user(username, "Q", "ignore_list") unless existsCheck(username)
    result = @db.exec( "select ignore_list from matches where name=$1 and account=$2", [username, @login])
    result.each do |man|
      array.push(man)
    end
    array.shift["ignore_list"].to_i == 1
  end

  def ignore_user(username)
    unless existsCheck(username)
      add_user(username, "Q", "hidden_users")
    end
    unless is_ignored(username)
      puts "Added to ignore list: #{username}" if verbose
      @db.exec( "update matches set ignore_list=$3 where name=$1 and account=$2", [username, @login, 1])
    else
      puts "User already ignored: #{username}" if verbose
    end
  end

  def unignore_user(username)
    @db.exec( "update matches set ignore_list=0 where name=$1 and account=$2", [username, @login])
  end

  def added_from(username, method)
    @db.exec("update matches set added_from=$1 where name=$2 and account=$3", [method, username, @login])
  end

  def get_added_from(username)
    row = @db.exec("select added_from from matches where account=$1 and name=$2", [@login, username])
    row[0]["added_from"].to_s
  end

  def existsCheck(username)
    @db.exec( "select 1 where exists(
          select 1
          from matches
          where name = $1
          and account = $2
      ) ", [username, @login]).any?
  end

  def import_user(args)
    name = args[:name]
    distance = args[:distance]
    age = args[:age]
    counts = args[:counts]
    last_visit = args[:last_visit]
    gender = args[:gender]
    @db.exec("insert into matches (name, counts, gender, age, distance, last_visit) values ($1, $2, $3, $4, $5, $6)", [name, counts, gender, age, distance, last_visit])
  end

  def remove_unknown_gender
    @db.exec("delete from matches where gender=$1 and account=$2", ["Q", @login])
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
