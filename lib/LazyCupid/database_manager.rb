module LazyCupid
  class DatabaseMgr
    attr_reader :login, :debug, :verbose


    def initialize(args)
      @did_migrate = false
      @login    = args[:login_name]
      @settings = args[:settings]
      @db = PGconn.connect( :dbname => @settings.db_name,
                            :password => @settings.db_pass,
                            :user => @settings.db_user
                            )
      import
      tasks     = args[:tasks]
      open_db
      db_tasks if tasks
      @verbose  = @settings.verbose
      @debug    = @settings.debug
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
      import
      puts "Executing db tasks..."
      delete_self_refs
      # @db.exec("delete from matches where distance > $1 and ignore_list=0 and account=$2", [@settings.max_distance, @login])
      @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Gay", @login]) unless @settings.visit_gay
      @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Straight", @login]) unless @settings.visit_straight
      @db.exec("update matches set ignore_list=1 where sexuality=$1 and account=$2", ["Bisexual", @login]) unless @settings.visit_bisexual
      begin
        @db.exec("alter table matches add column prev_visit integer")
      rescue
      end
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
        added_from text,
        city text,
        time_added text,
        smoking text,
        drinking text,
        kids text,
        drugs text,
        height text,
        body_type text,
        distance integer,
        added_from text,
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

    begin
      @db.exec("
        create table my_visits(
          id integer,
          account text,
          username text,
          visit_time integer
          )
        ")
    rescue Exception => e
      puts e.message
    end

    @did_migrate = true
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

  def get_user_info(username)
    @db.exec("select * from matches where name=$1 and account=$2", [username, @login])
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

  def new_user_smart_query
    visit_male, visit_female = "N"
    visit_male = "M" if @settings.visit_male == true
    visit_female = "F" if @settings.visit_female == true
    @db.exec("select * from matches
    where account=$3
    and counts = 0
    and (ignore_list=0 or ignore_list is null)
    and (gender=$1 or gender=$2)
    order by last_online desc, time_added asc", [visit_male, visit_female, @login])
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
    visit_male          = @settings.visit_male || nil
    visit_female        = @settings.visit_female || nil
    visit_gay           = @settings.visit_gay
    visit_bisexual      = @settings.visit_bisexual
    visit_straight      = @settings.visit_straight
    distance            = @settings.max_distance

    if visit_male
      male = "M"
    else
      male = "N"
    end
    if visit_female
      female = "F"
    else
      female = "N"
    end

    result          = @db.exec("
        select * from matches
         where account=$10
        and (last_visit <= $1 or last_visit is null)
         and counts between $2 and $3
         and (distance <= $4 or distance is null)
         and ignore_list = 0
         and (age between $5 and $6 or age is null)
         and (match_percent between $7 and 100 or match_percent is null or match_percent=0)
         and (gender=$8 or gender=$9)
         and (last_online > extract(epoch from (now() - interval '#{last_online_cutoff} days')))
         order by counts ASC, last_online DESC, match_percent DESC, distance ASC, height #{height_sort}, age #{age_sort}",
                               [min_time.to_i,
                                min_counts,
                                max_counts,
                                distance,
                                min_age,
                                max_age,
                                min_percent,
                                male,
                                female,
                                @login])
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
    distance        = @settings.max_distance

    result          = @db.exec("
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
                                    distance,
                                    min_age,
                                    max_age,
                                    min_percent,
                                    desired_gender])

    # result.close
    result[0][0].to_i
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

  def set_time_added(args)
    user = args[ :username]
    @db.exec("update matches set time_added=$1 where name=$2 and account=$3", [Time.now.to_i, user, @login])
  end

  def set_city(user, city)
    @db.exec("update matches set city=$1 where name=$2 and account=$3", [city, user, @login])
  end

  def set_gender(args)
    user = args[ :username]
    gender = args[ :gender]
    @db.exec("update matches set gender=$1 where name=$2 and account=$3", [gender, user, @login])
  end

  def set_sexuality(user, sexuality)
    @db.exec("update matches set sexuality=$1 where name=$2 and account=$3", [sexuality, user, @login])
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
    puts "Last Msg date updated: #{user}:#{date}" if verbose
    @db.exec("update matches set last_msg_time=$1 where name=$2 and account=$3", [date.to_i, user, @login])
  end

  def get_last_received_message_date(user)
    result = @db.exec("select last_msg_time from matches where name=$1 and account=$2", [user, @login])
    begin
      result.first["last_msg_time"].to_i
    rescue Exception => e
      # puts e.message
      # puts e.backtrace
      # sleep 10
      0
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
    # begin
    result[0]["last_visit"].to_i
    # rescue
    #   0
    # end
  end

  def get_prev_visit(user)
    result = @db.exec("select prev_visit from matches where account=$1 and name=$2", [@login, user])
    begin
      result[0]["prev_visit"].to_i
    rescue
      0
    end
  end


  def set_my_last_visit_date(user, date=Time.now.to_i)
    prev = get_my_last_visit_date(user)
    now = Time.now.to_i
    puts "Last visit: #{prev}" if debug
    puts "Now: #{now}" if debug
    @db.exec("update matches set prev_visit=$1 where name=$2 and account=$3", [get_my_last_visit_date(user), user, @login])
    @db.exec( "update matches set last_visit=$1 where name=$2 and account=$3", [Time.now.to_i, user, @login])
    @db.exec("insert into my_visits (username, account, visit_time) values ($1, $2, $3)", [user, @login, Time.now.to_i])
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
      @db.exec("insert into matches(name, counts, visitor_timestamp, ignore_list, account, added_from) values ($1, $2, $3, $4, $5, $6)", [visitor, 0, Time.now.to_i, 0, @login, "visitors"])
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
      set_user_details(user)
    end
  end

  def set_user_details(user)
    @db.exec("update matches
      set (gender, sexuality, match_percentage, state, distance, age, city, height, last_online, last_visit) =
      ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      where name=$11",
             [user[:gender],
              user[:sexuality],
              user[:match_percentage],
              user[:state],
              user[:distance],
              user[:age],
              user[:city],
              user[:height],
              user[:last_online],
              Time.now.to_i,
              user[:handle]])
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
end
